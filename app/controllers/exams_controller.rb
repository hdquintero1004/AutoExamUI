class ExamsController < ApplicationController
  before_action :check_user_log_in
  before_action :set_exam, only: [:show, :edit, :update, :destroy, :exam_version, :evaluate_answer, :scan_answer, :generate_version]

  # GET /exams
  # GET /exams.json
  def index
    @exams = Exam.all
  end

  # GET /exams/1
  # GET /exams/1.json
  def show
    @previous_version = []
    Dir.foreach(Rails.root().to_s + '/generated/Exam-' + @exam.id.to_s + '/generated'){|x| @previous_version << x if x[0] == 'v'}
    @previous_version = @previous_version.sort()
  end

  # GET /exams/new
  def new
    @exam = Exam.new
    @exam.signature_id = params[:signature_id]
  end

  # GET /exams/1/edit
  def edit
  end

  # GET /exams/1/select_questions
  def select_question
    @exam = Exam.find(params[:id])
  end

  # POST /exams/1/select_questions
  def update_master
    @exam = Exam.find(params[:id])
    @exam.json_master = JSON.dump($json_master)
    @exam.save

    set_master_txt

    redirect_to exam_path @exam.id
  end

  def update_json_master
    # Take the valid values for params[:key] entry in the exam ...

    in_range = true
    # If entry finish in '-numQuest' is the value for total number of question in the exam ...
    if params[:key][-9..-1] == '-numQuest'
      in_range = $json_master_validation[params[:key]][0] <= params[:value].to_i() && params[:value].to_i() <= $json_master_validation[params[:key]][1]
    # If entry finish in '-min' or '-max' is the value for minimum or maximum number or questions for each label in the exam ...
    elsif params[:key][-4..-1] == '-min' or params[:key][-4..-1] == '-max'
      in_range = (params[:value].to_i() >= $json_master_validation[params[:key][0..-5]+'-min'] and params[:value].to_i() <= $json_master_validation[params[:key][0..-5]+'-max'])
    end

    if in_range
      $json_master[params[:key]] = params[:value]
    else
      exam = Exam.find(params[:id])
      exam.json_master = JSON.dump($json_master)
      exam.save()
      respond_to do |format|
        format.js { render inline: "location.reload();" }
      end
    end
  end

  def generate_version
    # Generate a new version of the exam ...
    directory = Rails.root.to_s + '/generated/Exam-' + @exam.id.to_s
    Dir.chdir(directory)
    if not system('autoexam gen -c ' + @exam.amount.to_s)
      directory += '/generated'
      Dir.chdir(directory)
      last_version = 0
      Dir.foreach(directory){|x| last_version = x[1..-1].to_i if x[0] == 'v' and x[1..-1].to_i > last_version}
      system('rm -r ' + directory + '/v' + last_version.to_s)
      redirect_to @exam, :notice => "A Error ocurred when trying to create a new version."
      return
    end

    directory = File.join(directory, '/generated/last/')
    # Set grader.txt file ...
    content = []

    # Read the first line of existing grader.txt file to know the version ...
    file = File.open(directory + 'grader.txt', "r")
    version = file.readline.to_i
    file.close

    json_version_grader = JSON.load(@exam.json_versions_grader)

    if json_version_grader.nil?
      json_version_grader = {}
    end

    json_version_grader[version] = {}
    content << version
    # Create content for new grader.txt file ...
    json_grader = JSON.load(@exam.json_grader)
    json_grader.keys.sort.each do |identifier|
      content << identifier
      content << "total: " + json_grader[identifier].size.to_s

      json_version_grader[version][identifier]=[]

      line = ""
      json_grader[identifier].each do |option|
        line += ' ' if line != ""
        line += option[0].to_s + ':' + option[1].to_s
        json_version_grader[version][identifier] << [option[0].to_s, option[1].to_s, option[2].to_s]
      end

      content << line
      content << ""

    end

    @exam.json_versions_grader = JSON.dump(json_version_grader)
    @exam.save

    content = content.join("\n")
    File.open(directory + 'grader.txt', "w") do |file|
      file.write(content)
    end

    redirect_to show_pdf_file_exam_path :path => File.join(directory, 'pdf/Master.pdf')
  end

  # POST /exams
  # POST /exams.json
  def create
    @exam = Exam.new(exam_params)
    set_labels
    set_json_master
    respond_to do |format|
      if @exam.save
        format.html { redirect_to select_questions_exam_path(@exam), notice: 'Exam was successfully created.' }
        format.json { render :select_question, status: :ok, location: @exam }
      else
        format.html { render :new }
        format.json { render json: @exam.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /exams/1
  # PATCH/PUT /exams/1.json
  def update
    set_labels
    set_json_master
    respond_to do |format|
      if @exam.update(exam_params)
        format.html { redirect_to select_questions_exam_path(@exam), notice: 'Exam was successfully updated.' }
        format.json { render :select_question, status: :ok, location: @exam }
      else
        format.html { render :edit }
        format.json { render json: @exam.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /exams/1
  # DELETE /exams/1.json
  def destroy
    go_back = @exam.signature_id
    @exam.destroy
    respond_to do |format|
      format.html { redirect_to signature_path(go_back), notice: 'Exam was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # GET /exams/1/exam_version?version=...
  def exam_version
    # Display a version view of the exam ...
    @files_path = Rails.root.to_s + '/generated/Exam-' + @exam.id.to_s + '/generated/v' + params[:version] + '/pdf'
    @file_list = []
    Dir.foreach(@files_path){|f| @file_list << f if f[0] != '.'}
    @file_list = @file_list.sort()

    @statics = {}

    # Construct table
    @statics['table'] = []
    @statics['table'][1] = []

    # Construct graphs
    @statics['graph'] = [['Right Answer'], ['Wrong Answer']]
    @statics['marked_options'] = {}


    @statics['table'][0] = JSON.load(@exam.json_versions_grader)[params[:version]].keys

    @statics['graph'][0] += [0]*@statics['table'][0].size
    @statics['graph'][1] += [0]*@statics['table'][0].size

    document_ids = Static.where({exam_id: @exam.id, exam_version: params[:version].to_i}).group(:document_id).count(:document_id)
    document_ids.keys.each do |document|
      sum = 0
      row = []
      row << [document, 2]

      @statics['table'][0].each do |question|
        answer = Static.where({exam_id: @exam.id, exam_version: params[:version].to_i, document_id: document, question_id: question.to_i}).first
        if answer.nil?
          column = ["", 2, []]
        else
          column = [answer.note, 0, []]
          sum += answer.note
          if answer.right == 0
            @statics['graph'][1][question.to_i]+=1
          else
            @statics['graph'][0][question.to_i]+=1
            column[1] = 1
          end

          if @statics['marked_options'][question].nil?
            @statics['marked_options'][question] = JSON.load(answer.answer)['marked_options']
            index = 0
            @statics['marked_options'][question].each do |option|
              column[2] << option if index > 0
              index += 1
            end
          else
            index = 0
            JSON.load(answer.answer)['marked_options'].each do |option|
              @statics['marked_options'][question][index] += option
              column[2] << option if index > 0
              index += 1
            end
          end
          @statics['marked_options'][question][0] = "Times"
        end
        row << column
      end

      row << [sum, 2]
      @statics['table'][1] << row
    end
  end

  def evaluate_answer

  end

  def scan_answer
    directory = Rails.root.to_s + '/generated/Exam-' + @exam.id.to_s
    Dir.chdir(directory)
    system('mkdir temp')

    # Saving image in server.
    File.open(directory + '/temp/answer.jpeg', 'wb') do |f|
      f.write(params[:image].read)
      f.close
    end

    # scanning image to determine if contains a exam answer
    system('autoexam scan -f temp > log.txt')

    # checking the results of scan
    result = []
    File.open(directory + '/results.json', 'r') do |f|
      result = f.readlines
      f.close
    end

    result = JSON.load(result.join(""))

    if result.blank?
      # error with image
      redirect_to evaluate_answer_exam_path(:version=> params[:version]), :notice => "Error while scan the document. Try move the document in front camera."
    elsif result[result.keys[0]]['exam_id'] != params[:version].to_i
      # the answer is not for this version
      redirect_to evaluate_answer_exam_path(:version=> params[:version]), :notice => "The document not correspond to this version."
    else
      # valid answer. add to statics
      document_id = result[result.keys[0]]['id']
      result[result.keys[0]]['questions'].each do |q|
        question_id = q['id'].to_s
        answer = {}

        # Calculate the note ...
        note = 0
        index = 0
        right = 1
        answer['marked_options'] = ['Options']
        JSON.load(@exam.json_versions_grader)[params[:version]][question_id].each do |o|
          if q['answers'].find_index(index).nil?
            answer['marked_options'] << 0
            note += o[1].to_i
            if o[2] == "1"
              right = 0
            end
          else
            answer['marked_options'] << 1
            note += o[0].to_i
            if o[2] == "0"
              right = 0
            end
          end

          index+=1
        end

        answer = JSON.dump(answer)
        stats = Static.all.where({exam_id: @exam.id, exam_version: params[:version].to_i, document_id: document_id, question_id: question_id}).first
        if stats.nil?
          # Insert stats in DB
          stats = Static.new(exam_id: @exam.id, exam_version: params[:version].to_i, document_id: document_id, question_id: question_id, answer: answer, note: note, right: right)
        else
          stats.answer = answer
          stats.right = right
        end

        stats.save
      end
      redirect_to exam_version_exam_path :version => params[:version]
    end

    # remove temporaly files
    system('rm -r temp')
    #system('rm log.txt')
    system('rm results.json')

  end

  def show_pdf_file
  # This method is use to show in browser exams pdf files.

    directory = params[:path]

    # if to_do.nil? = true is because only need to show the pdf file.
    if params[:to_do].nil?
      send_file(params[:path], :disposition => 'inline')
    # else we need to pack all pdf requested and send. Request allows are 'Test', 'Answer', 'Table'.
    elsif params[:to_do] == 'Test' or params[:to_do] == 'Answer'
      Dir.chdir(directory)

      # Create a temporal folder ...
      file_name = directory.split('/')[-4] + '_' + directory.split('/')[-2] + '_' + params[:to_do]
      system('mkdir ' + file_name)

      # Copying the requested files to the new folder ...
      file_list = []
      Dir.foreach('.'){|f| file_list << f if f[0..params[:to_do].length-1] == params[:to_do]}

      file_list.each() do |f|
        system('cp ' + f + ' ./' + file_name)
      end

      # Packing the new folder in a .tar file and sending ...
      system('tar -cf ' + file_name + '.tar ' + file_name)
      send_file(directory + '/' + file_name + '.tar', :disposition => 'attachment')

      # Removing temporal files and directories ...
      system('rm -r ' + file_name)
    elsif params[:to_do] == 'Table'
      Dir.chdir(directory)
      File.open(directory + '/notes.txt', 'wb') do |f|
        f.write(params[:content])
      end
      send_file(directory + '/notes.txt', :disposition => 'attachment')
    end
  end

  private
    def set_master_txt
      # Set the master.txt file foreach exam.

      # Store and update information for grader.txt file
      grader_txt = { }

      # Generate if not exits the directory of AutoExam project foreach exam ...
      directory = Rails.root.to_s + '/generated'
      directory += '/Exam-' + @exam.id.to_s
      system('autoexam new -f ' + directory + ' Exam-' + @exam.id.to_s) unless File.exist?(directory)

      exam_labels = @exam.labels.remove(' ').split(',')
      json_master = JSON.load(@exam.json_master)

      # In content store the lines includes in master.txt file ...
      content = ["% ============================================================================"]
      content << "% #{@exam.title} "
      content << "% ============================================================================"
      content << "% Lines starting with a % are ignored."
      content << "% Blank lines are ignored as well."
      content << ""
      content << "% the number of questions in each document"
      content << "total: #{json_master[@exam.id.to_s + '-numQuest'].to_s}"
      content << ""
      content << "% the tags that will be used in the test"
      content << "% each tag comes with the minimun number of questions"

      # Only store in master.txt file the labels that have more than 0 questions ...
      correct_labels = []
      exam_labels.each do |label|
        if json_master[label + "-min"].to_i > 0
          content << '@' + label + ': ' + json_master[label + "-min"].to_s
          correct_labels << label
        end
      end

      # Finish head of master.txt file with 42 '-' characters
       content << ""
      content << "------------------------------------------"

      # Include in master.txt file all questions ...
      identifier = 0
      Question.all.each do |q|
        tags = []
        q.labels.remove(' ').split(',').each do |l|
          tags << l if not correct_labels.find_index(l).nil?
        end

        if not tags.empty?
          identifier += 1

          content << "(" + identifier.to_s + ") %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
          content << tags.map {|e| "@" + e}.join(" ")
          content << q.body

          # Entry in grader.txt file foreach question in master.txt file ...
          grader_txt[identifier] = []

          Option.where(:question_id => q.id).each do |o|
            line = "_"
            line += "x" if o.true_or_false == 1
            line += " "
            line += o.body
            content << line

            # Adding values for check and uncheck the options of each question ...
            grader_txt[identifier].append([json_master[q.id.to_s+"-"+o.id.to_s+"-checked"], json_master[q.id.to_s+"-"+o.id.to_s+"-uncheck"], o.true_or_false])
          end
          content << ""
        end
      end

      # Save in json_grader field of exam the information needed ...
      @exam.json_grader = JSON.dump(grader_txt)
      @exam.save()

      content = content.join("\n")
      directory += "/master.txt"
      File.open(directory, "w") do |file|
        file.write(content)
      end

    end

    def set_labels
      labels = ""
      signature_labels = Signature.find(@exam.signature_id).labels
      if signature_labels.nil?
        return
      end
      signature_labels.remove(' ').split(',').each do |l|
        if not params[l].nil?
          labels += ", " if labels.length != 0
          labels += l
        end
      end
      @exam.labels = labels
    end

    def set_json_master
      # create json_master dic to store values for all questions and options in the exam...

      # previous values of json_master
      previous_json = JSON.load(@exam.json_master)
      previous_json = {} if previous_json.nil?

      json_master = {}
      json_master_validation = {}

      # entry 'exam_id-numQuest' = number of question in each exam
      json_master[@exam.id.to_s + '-numQuest'] = 0
      json_master[@exam.id.to_s + '-numQuest'] = previous_json[@exam.id.to_s + '-numQuest'] if not previous_json[@exam.id.to_s + '-numQuest'].nil?

      # entry 'exam_id-numQuest' = valid range for number of question in each exam
      json_master_validation[@exam.id.to_s + '-numQuest'] = [0,0]

      exams_labels = {}
      @exam.labels.remove(' ').split(',').each do |l|
        exams_labels[l] = 0

        # entries 'label-min' and 'label-max' = minimum and maximum number of question foreach label
        json_master[l+"-min"] = 0
        json_master[l+"-min"] = previous_json[l+"-min"] if not previous_json[l+"-min"].nil?
        json_master[l+"-max"] = 0
        json_master[l+"-max"] = previous_json[l+"-max"] if not previous_json[l+"-max"].nil?

        # entries 'label-min' and 'label-max' = minimum and maximum value for number of question foreach label
        json_master_validation[l+"-min"] = 0
        json_master_validation[l+"-max"] = 0
      end

      Question.where(:signature_id => @exam.signature_id).each do |q|
        q.labels.remove(' ').split(',').each do |l|
          if not exams_labels.keys.find_index(l).nil?
            exams_labels[l] += 1

            # entries 'question_id-min' and 'question_id-max' = minimum and maximum cost foreach question
            json_master[q.id.to_s+"-minCost"] = 0
            json_master[q.id.to_s+"-minCost"] = previous_json[q.id.to_s+"-minCost"] if not previous_json[q.id.to_s+"-minCost"].nil?
            json_master[q.id.to_s+"-maxCost"] = 0
            json_master[q.id.to_s+"-maxCost"] = previous_json[q.id.to_s+"-maxCost"] if not previous_json[q.id.to_s+"-maxCost"].nil?
            Option.where(:question_id => q.id).each do |o|
              # entries 'question_id-option_id-uncheck' and 'question_id-option_id-checked' = cost for uncheck and check each option
              json_master[q.id.to_s+"-"+o.id.to_s+"-uncheck"] = -1 * (o.true_or_false - 1)
              json_master[q.id.to_s+"-"+o.id.to_s+"-uncheck"] = previous_json[q.id.to_s+"-"+o.id.to_s+"-uncheck"] if not previous_json[q.id.to_s+"-"+o.id.to_s+"-uncheck"].nil?
              json_master[q.id.to_s+"-"+o.id.to_s+"-checked"] = o.true_or_false
              json_master[q.id.to_s+"-"+o.id.to_s+"-checked"] = previous_json[q.id.to_s+"-"+o.id.to_s+"-checked"] if not previous_json[q.id.to_s+"-"+o.id.to_s+"-checked"].nil?
            end
          end
        end
      end

      count = 0
      exams_labels.keys.each do |l|
        json_master_validation[l+"-max"] = exams_labels[l]
        count += exams_labels[l]
      end

      json_master_validation[@exam.id.to_s + '-numQuest'][1] = count

      @exam.json_master = JSON.dump(json_master)
      @exam.json_master_validation = JSON.dump(json_master_validation)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_exam
      @exam = Exam.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def exam_params
      params.require(:exam).permit(:title, :header, :description, :labels, :amount, :students_list, :signature_id)
    end

    def check_user_log_in
      if not user_signed_in?
        redirect_to(user_session_path)
      end
    end
end