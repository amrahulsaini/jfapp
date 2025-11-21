class StudentModel {
  final String rollNo;
  final String enrollmentNo;
  final String studentName;
  final String fatherName;
  final String motherName;
  final String branch;
  final String? mobileNo;
  final String studentEmailId;
  final String? studentSection;

  StudentModel({
    required this.rollNo,
    required this.enrollmentNo,
    required this.studentName,
    required this.fatherName,
    required this.motherName,
    required this.branch,
    this.mobileNo,
    required this.studentEmailId,
    this.studentSection,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      rollNo: json['roll_no'] ?? '',
      enrollmentNo: json['enrollment_no'] ?? '',
      studentName: json['student_name'] ?? '',
      fatherName: json['father_name'] ?? '',
      motherName: json['mother_name'] ?? '',
      branch: json['branch'] ?? '',
      mobileNo: json['mobile_no'],
      studentEmailId: json['student_emailid'] ?? '',
      studentSection: json['student_section'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roll_no': rollNo,
      'enrollment_no': enrollmentNo,
      'student_name': studentName,
      'father_name': fatherName,
      'mother_name': motherName,
      'branch': branch,
      'mobile_no': mobileNo,
      'student_emailid': studentEmailId,
      'student_section': studentSection,
    };
  }
}
