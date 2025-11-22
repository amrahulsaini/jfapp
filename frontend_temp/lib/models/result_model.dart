class ResultModel {
  final String courseTitle;
  final String courseCode;
  final String marksMidterm;
  final String marksEndterm;
  final String grade;
  final double sgpa;
  final String remarks;
  final String? subjectPdfPath;

  ResultModel({
    required this.courseTitle,
    required this.courseCode,
    required this.marksMidterm,
    required this.marksEndterm,
    required this.grade,
    required this.sgpa,
    required this.remarks,
    this.subjectPdfPath,
  });

  factory ResultModel.fromJson(Map<String, dynamic> json) {
    return ResultModel(
      courseTitle: json['course_title'] ?? '',
      courseCode: json['course_code'] ?? '',
      marksMidterm: json['marks_midterm'] ?? '',
      marksEndterm: json['marks_endterm'] ?? '',
      grade: json['grade'] ?? '',
      sgpa: (json['sgpa'] is String) 
          ? double.tryParse(json['sgpa']) ?? 0.0 
          : (json['sgpa']?.toDouble() ?? 0.0),
      remarks: json['remarks'] ?? '',
      subjectPdfPath: json['subject_pdf_path'],
    );
  }
}
