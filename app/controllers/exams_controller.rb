class ExamsController < ApplicationController
  before_action :set_exam, only: [:show, :edit, :update, :destroy]

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
    valid_value = $json_master_validations[params[:key]]

    in_range = false
    if params[:key] == '-numQuest'
      in_range = params[:value] <= valid_value[1] && params[:value] >= valid_value[0]
    elsif params[:key] == '-min'
      in_range = params[:value] >= valid_value
    else
      in_range = params[:value] <= valid_value
    end

    if in_range
      $json_master[params[:key]] = params[:value]
      render :nothing => true
    else
      render :nothing => true
    end
  end

  def generate_latex
    @exam = Exam.find(params[:id])
    directory = Rails.root.to_s + '/generated/Exam-' + @exam.id.to_s
    Dir.chdir(directory)
    system('autoexam gen -c ' + @exam.amount.to_s)

    master_file = File.join(directory, '/generated/last/pdf/Master.pdf')
    send_file(master_file, :filename => "document.pdf", :type => "application/pdf", :disposition => 'inline')

    redirect_to signature_path @exam.signature_id
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

  def exam_version
    @exam = Exam.find(params[:id])
    @file_list = []
    Dir.foreach(Rails.root.to_s + '/generated/Exam-' + @exam.id.to_s + '/generated/v' + params['version'] + '/pdf'){|f| @file_list << f if f[0] != '.'}
    @file_list = @file_list.sort()
  end

  private
    def set_master_txt
      directory = Rails.root.to_s + '/generated'
      directory += '/Exam-' + @exam.id.to_s
      system('autoexam new -f ' + directory + ' Exam-' + @exam.id.to_s) unless File.exist?(directory)

      exam_labels = @exam.labels.remove(' ').split(',')
      json_master = JSON.load(@exam.json_master)

      content = ["% ============================================================================"]
      content << "% #{@exam.title} "
      content << "% ============================================================================"
      content << "% Lines starting with a % are ignored."
      content << "% Blank lines are ignored as well."
      content << ""
      content << "% the number of questions"
      content << "total: #{json_master[@exam.id.to_s + '-numQuest'].to_s}"
      content << ""
      content << "% the tags that will be used in the test"
      content << "% each tag comes with the minimun number of questions"

      correct_labels = []
      exam_labels.each do |label|
        if json_master[label + "-min"].to_i > 0
          content << '@' + label + ': ' + json_master[label + "-min"].to_s
          correct_labels << label
        end
      end

      content << ""
      content << "----------------------------------------- "

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
          Option.where(:question_id => q.id).each do |o|
            line = "_"
            line += "x" if o.true_or_false == 1
            line += " "
            line += o.body
            content << line
          end
          content << ""
        end
      end

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
      json_master_validations = {}

      # entry 'exam_id-numQuest' = number of question in each exam
      json_master[@exam.id.to_s + '-numQuest'] = 0
      json_master[@exam.id.to_s + '-numQuest'] = previous_json[@exam.id.to_s + '-numQuest'] if not previous_json[@exam.id.to_s + '-numQuest'].nil?

      # entry 'exam_id-numQuest' = valid range for number of question in each exam
      json_master_validations[@exam.id.to_s + '-numQuest'] = [0,0]

      exams_labels = {}
      @exam.labels.remove(' ').split(',').each do |l|
        exams_labels[l] = 0

        # entries 'label-min' and 'label-max' = minimum and maximum number of question foreach label
        json_master[l+"-min"] = 0
        json_master[l+"-min"] = previous_json[l+"-min"] if not previous_json[l+"-min"].nil?
        json_master[l+"-max"] = 0
        json_master[l+"-max"] = previous_json[l+"-max"] if not previous_json[l+"-max"].nil?

        # entries 'label-min' and 'label-max' = minimum and maximum value for number of question foreach label
        json_master_validations[l+"-min"] = 0
        json_master_validations[l+"-max"] = 0
      end

      Question.where(:signature_id => @exam.signature_id).each do |q|
        q.labels.remove(' ').split(',').each do |l|
          if not exams_labels.find_index(l).nil?
            exams_labels[l] += 1

            # entries 'label-question_id-min' and 'label-question_id-max' = minimum and maximum cost foreach question
            json_master[l+"-"+q.id.to_s+"-min"] = 0
            json_master[l+"-"+q.id.to_s+"-min"] = previous_json[l+"-"+q.id.to_s+"-min"] if not previous_json[l+"-"+q.id.to_s+"-min"].nil?
            json_master[l+"-"+q.id.to_s+"-max"] = 0
            json_master[l+"-"+q.id.to_s+"-max"] = previous_json[l+"-"+q.id.to_s+"-max"] if not previous_json[l+"-"+q.id.to_s+"-max"].nil?
            Option.where(:question_id => q.id).each do |o|
              # entries 'label-question_id-option_id-uncheck' and 'label-question_id-option_id-checked' = cost for uncheck and check each option
              json_master[l+"-"+q.id.to_s+"-"+o.id.to_s+"-uncheck"] = -1 * (o.true_or_false - 1)
              json_master[l+"-"+q.id.to_s+"-"+o.id.to_s+"-uncheck"] = previous_json[l+"-"+q.id.to_s+"-"+o.id.to_s+"-uncheck"] if not previous_json[l+"-"+q.id.to_s+"-"+o.id.to_s+"-uncheck"].nil?
              json_master[l+"-"+q.id.to_s+"-"+o.id.to_s+"-checked"] = o.true_or_false
              json_master[l+"-"+q.id.to_s+"-"+o.id.to_s+"-checked"] = previous_json[l+"-"+q.id.to_s+"-"+o.id.to_s+"-checked"] if not previous_json[l+"-"+q.id.to_s+"-"+o.id.to_s+"-checked"].nil?
            end
          end
        end
      end

      count = 0
      exams_labels.keys.each do |l|
        json_master_validations[l+"-max"] = exams_labels[l]
        count += exams_labels[l]
      end

      json_master_validations[@exam.id.to_s + '-numQuest'][1] = count

      @exam.json_master = JSON.dump(json_master)
      @exam.json_master_validations = JSON.dump(json_master_validations)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_exam
      @exam = Exam.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def exam_params
      params.require(:exam).permit(:title, :header, :description, :labels, :amount, :students_list, :signature_id)
    end
end