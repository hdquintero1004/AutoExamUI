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
    redirect_to home_index_path
  end

  def update_json_master
    $json_master[params[:key]] = params[:value]
    render :nothing => true
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

  private
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
      previous_json = JSON.load(@exam.json_master)
      previous_json = {} if previous_json.nil?

      json_master = {}

      exams_labels = @exam.labels.remove(' ').split(',')
      exams_labels.each do |l|
        json_master[l+"-min"] = nil if previous_json[l+"-min"].nil?; previous_json[l+"-min"]
        json_master[l+"-max"] = nil if previous_json[l+"-max"].nil?; previous_json[l+"-max"]
      end

      Question.where(:signature_id => @exam.signature_id).each do |q|
        q.labels.remove(' ').split(',').each do |l|
          if not exams_labels.find_index(l).nil?
            json_master[l+"-"+q.id.to_s+"-min"] = nil if previous_json[l+"-"+q.id.to_s+"-min"].nil?; previous_json[l+"-"+q.id.to_s+"-min"]
            json_master[l+"-"+q.id.to_s+"-max"] = nil if previous_json[l+"-"+q.id.to_s+"-max"].nil?; previous_json[l+"-"+q.id.to_s+"-max"]
            Option.where(:question_id => q.id).each do |o|
              json_master[l+"-"+q.id.to_s+"-"+o.id.to_s+"-uncheck"] = nil if previous_json[l+"-"+q.id.to_s+"-"+o.id.to_s+"-uncheck"].nil?; previous_json[l+"-"+q.id.to_s+"-"+o.id.to_s+"-uncheck"]
              json_master[l+"-"+q.id.to_s+"-"+o.id.to_s+"-checked"] = nil if previous_json[l+"-"+q.id.to_s+"-"+o.id.to_s+"-checked"].nil?; previous_json[l+"-"+q.id.to_s+"-"+o.id.to_s+"-checked"]
            end
          end
        end
      end
      @exam.json_master = JSON.dump(json_master)
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
