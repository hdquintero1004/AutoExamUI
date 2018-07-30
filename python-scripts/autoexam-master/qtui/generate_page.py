from PyQt4.QtGui import *
from PyQt4.QtCore import Qt
from PyQt4 import uic
import os
from os.path import join, exists
from glob import glob
import api
from model import Tag

TEMPLATE_PATH = 'qtui/master.jinja'
LAST_GENERATED_PATH = 'generated/last/'

class GeneratePage(QWizardPage):
    path = "qtui/ui/page2_generate.ui"

    def __init__(self, project, parentW=None):
        super(GeneratePage, self).__init__()
        self.ui = uic.loadUi(join(os.environ['AUTOEXAM_FOLDER'], self.path), self)
        self.project = project

        self.ui.questionCountSpin.setValue(self.project.total_questions_per_exam)
        self.ui.examCountSpin.setValue(self.project.total_exams_to_generate)

        self.ui.questionCountSpin.valueChanged.connect(self.updateProject)
        self.ui.examCountSpin.valueChanged.connect(self.updateProject)

        self.parentWizard = parentW

    def gridItemAt(self, r, c):
         self.grid.itemAtPosition(r, c).widget()

    def listGrid(self):
        for i in range(self.grid.count()):
            item = self.grid.itemAt(i)
            # print i, type(item.widget() if item.widget() else item).__name__

    def clearGrid(self):
        widget = QWidget()
        layout = QGridLayout()
        widget.setLayout(layout)
        self.ui.scrollArea.widget().destroy()
        self.ui.scrollArea.setWidget(widget)
        self.ui.tagOrderWidget.clear()
        self.grid = layout

    def setupTagMenu(self):
        self.clearGrid()
        for i, tag in enumerate(self.project.tags):
            self.grid.addWidget(QLabel(tag.name), i, 0, Qt.AlignTop|Qt.AlignRight)
            spinbox = QSpinBox()
            spinbox.setValue(tag.min_questions)
            self.grid.addWidget(spinbox, i, 2, Qt.AlignTop)
            self.ui.tagOrderWidget.addItem(tag.name)

        hs = QSpacerItem(40, 20, hPolicy=QSizePolicy.Fixed)
        self.grid.addItem(hs, 0, 1)

        vs1 = QSpacerItem(20, 300, vPolicy=QSizePolicy.Expanding)
        vs2 = QSpacerItem(20, 300, vPolicy=QSizePolicy.Expanding)
        vs3 = QSpacerItem(20, 300, vPolicy=QSizePolicy.Expanding)
        pos = len(self.project.tags)
        self.grid.addItem(vs1, pos, 0)
        self.grid.addItem(vs2, pos, 1)
        self.grid.addItem(vs3, pos, 2)

    def updateTags(self):
        # import pdb; pdb.set_trace()
        self.listGrid()
        tags = []
        for i in range(len(self.project.tags)):
            name = str(self.grid.itemAt(2*i).widget().text())
            minq = self.grid.itemAt(2*i+1).widget().value()
            tags.append(Tag(name, minq))

        ordered_tags = []
        for i in range(self.ui.tagOrderWidget.count()):
            current_tag = self.ui.tagOrderWidget.item(i)
            for tag in tags:
                if tag.name == str(current_tag.text()):
                    ordered_tags.append(tag)

        self.project.tags = ordered_tags

    def initializePage(self):
        self.setupTagMenu()

    def validatePage(self):
        regen = True
        if exists(LAST_GENERATED_PATH):
            confirm_regen = QMessageBox.question(None, "Regenerate?", "There is already an exam generated in this folder. Would you like to regenerate it? \n (WARNING: This will efectively render unusable your current tests if you have already printed them! Normally, you should just select no.)", QMessageBox.Yes | QMessageBox.No )
            regen = confirm_regen == QMessageBox.Yes
        if regen:
            return self.generate()
        return True

    def generate(self):
        # Both master and exam generation are being done here temporally

        self.updateProject()

        msgBox = QMessageBox()
        msgBox.setText("The master file will now be generated.")
        msgBox.setModal(True)
        msgBox.exec_()

        master_data = api.render_master(self.project, join(os.environ['AUTOEXAM_FOLDER'], TEMPLATE_PATH))
        api.save_master(master_data)

        ret = api.gen(**{"tests_count": self.project.total_exams_to_generate,
                   "dont_shuffle_tags": self.ui.keepTagOrderCheck.isChecked(),
                   "sort_questions": not self.ui.shuffleQuestionsCheck.isChecked(),
                   "dont_shuffle_options": not self.ui.shuffleAnswersCheck.isChecked()
                   })

        if ret == 0:
            self.showModalMsg("The exam has been successfully generated.")
            return True
        else:
            self.showModalMsg(
                "There was an error while generating the test."
                "\nPlease check the console for details.")
            return False

    def showModalMsg(self, msg):
        msgBox = QMessageBox()
        msgBox.setText(msg)
        msgBox.setModal(True)
        msgBox.exec_()

    def updateProject(self):
        self.project.total_questions_per_exam = self.ui.questionCountSpin.value()
        self.project.total_exams_to_generate = self.ui.examCountSpin.value()
        self.updateTags()


if __name__ == '__main__':
    import sys
    app = QApplication(sys.argv)
    win = GeneratePage()
    win.show()
    sys.exit(app.exec_())
