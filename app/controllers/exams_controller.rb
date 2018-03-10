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

  # POST /exams
  # POST /exams.json
  def create
    @exam = Exam.new(exam_params)
    set_labels
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

    # Use callbacks to share common setup or constraints between actions.
    def set_exam
      @exam = Exam.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def exam_params
      params.require(:exam).permit(:title, :header, :description, :labels, :amount, :students_list, :signature_id)
    end
end
