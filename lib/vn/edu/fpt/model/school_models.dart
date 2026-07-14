class LinkedStudent {
  const LinkedStudent({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.status,
    this.email,
    this.className,
  });

  final int id;
  final String userName;
  final String fullName;
  final String? email;
  final String? className;
  final String status;

  factory LinkedStudent.fromJson(Map<String, dynamic> json) {
    return LinkedStudent(
      id: _requiredInt(json['id'], 'id'),
      userName: _text(json['userName']),
      fullName: _text(json['fullName']),
      email: _nullableText(json['email']),
      className: _nullableText(json['className']),
      status: _text(json['status']),
    );
  }
}

class SchoolSemester {
  const SchoolSemester({
    required this.id,
    required this.name,
    required this.schoolYear,
    required this.startDate,
    required this.endDate,
  });

  final int id;
  final String name;
  final String schoolYear;
  final DateTime startDate;
  final DateTime endDate;

  factory SchoolSemester.fromJson(Map<String, dynamic> json) {
    return SchoolSemester(
      id: _requiredInt(json['id'], 'id'),
      name: _text(json['name']),
      schoolYear: _text(json['schoolYear']),
      startDate: _requiredDate(json['startDate'], 'startDate'),
      endDate: _requiredDate(json['endDate'], 'endDate'),
    );
  }

  String get displayName => schoolYear.isEmpty ? name : '$name - $schoolYear';
}

class SchoolSubject {
  const SchoolSubject({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.credits,
  });

  final int id;
  final String subjectCode;
  final String subjectName;
  final int credits;

  factory SchoolSubject.fromJson(Map<String, dynamic> json) {
    return SchoolSubject(
      id: _requiredInt(json['id'], 'id'),
      subjectCode: _text(json['subjectCode']),
      subjectName: _text(json['subjectName']),
      credits: _requiredInt(json['credits'], 'credits'),
    );
  }
}

class ApplicationType {
  const ApplicationType({
    required this.id,
    required this.name,
    this.description,
  });

  final int id;
  final String name;
  final String? description;

  factory ApplicationType.fromJson(Map<String, dynamic> json) {
    return ApplicationType(
      id: _requiredInt(json['id'], 'id'),
      name: _text(json['name']),
      description: _nullableText(json['description']),
    );
  }
}

class StudentApplication {
  const StudentApplication({
    required this.id,
    required this.userId,
    required this.applicationTypeId,
    required this.title,
    required this.content,
    required this.status,
    this.studentCode,
    this.studentName,
    this.className,
    this.applicationTypeName,
    this.responseNote,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final int applicationTypeId;
  final String title;
  final String content;
  final String status;
  final String? studentCode;
  final String? studentName;
  final String? className;
  final String? applicationTypeName;
  final String? responseNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StudentApplication.fromJson(Map<String, dynamic> json) {
    return StudentApplication(
      id: _requiredInt(json['id'], 'id'),
      userId: _requiredInt(json['userId'], 'userId'),
      applicationTypeId: _requiredInt(
        json['applicationTypeId'],
        'applicationTypeId',
      ),
      title: _text(json['title']),
      content: _text(json['content']),
      status: _text(json['status']),
      studentCode: _nullableText(json['studentCode']),
      studentName: _nullableText(json['studentName']),
      className: _nullableText(json['className']),
      applicationTypeName: _nullableText(json['applicationTypeName']),
      responseNote: _nullableText(json['responseNote']),
      createdAt: _nullableDate(json['createdAt']),
      updatedAt: _nullableDate(json['updatedAt']),
    );
  }
}

class TeacherGrade {
  const TeacherGrade({
    required this.id,
    required this.userId,
    required this.studentCode,
    required this.studentName,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.semesterId,
    required this.semesterName,
    required this.totalScore,
    required this.items,
    this.className,
    this.letterGrade,
  });

  final int id;
  final int userId;
  final String studentCode;
  final String studentName;
  final String? className;
  final int subjectId;
  final String subjectCode;
  final String subjectName;
  final int semesterId;
  final String semesterName;
  final double? totalScore;
  final String? letterGrade;
  final List<TeacherGradeItem> items;

  factory TeacherGrade.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Invalid teacher grade field: items');
    }

    return TeacherGrade(
      id: _requiredInt(json['id'], 'id'),
      userId: _requiredInt(json['userId'], 'userId'),
      studentCode: _text(json['studentCode']),
      studentName: _text(json['studentName']),
      className: _nullableText(json['className']),
      subjectId: _requiredInt(json['subjectId'], 'subjectId'),
      subjectCode: _text(json['subjectCode']),
      subjectName: _text(json['subjectName']),
      semesterId: _requiredInt(json['semesterId'], 'semesterId'),
      semesterName: _text(json['semesterName']),
      totalScore: json['totalScore'] == null
          ? null
          : _doubleValue(json['totalScore'], 'totalScore'),
      letterGrade: _nullableText(json['letterGrade']),
      items: rawItems
          .map((item) => TeacherGradeItem.fromJson(_jsonMap(item, 'items')))
          .toList(growable: false),
    );
  }
}

class TeacherGradeItem {
  const TeacherGradeItem({
    required this.name,
    required this.weight,
    required this.score,
    this.id,
  });

  final int? id;
  final String name;
  final double weight;
  final double score;

  factory TeacherGradeItem.fromJson(Map<String, dynamic> json) {
    return TeacherGradeItem(
      id: json['id'] == null ? null : _requiredInt(json['id'], 'id'),
      name: _text(json['name']),
      weight: _doubleValue(json['weight'], 'weight'),
      score: _doubleValue(json['score'], 'score'),
    );
  }

  Map<String, dynamic> toRequestJson() {
    return <String, dynamic>{
      'name': name.trim(),
      'weight': weight,
      'score': score,
    };
  }
}

int _requiredInt(dynamic value, String fieldName) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed != null) return parsed;
  throw FormatException('Invalid integer field: $fieldName');
}

double _doubleValue(dynamic value, String fieldName) {
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value?.toString() ?? '');
  if (parsed != null) return parsed;
  throw FormatException('Invalid decimal field: $fieldName');
}

DateTime _requiredDate(dynamic value, String fieldName) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed != null) return parsed;
  throw FormatException('Invalid date field: $fieldName');
}

DateTime? _nullableDate(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

Map<String, dynamic> _jsonMap(dynamic value, String fieldName) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw FormatException('Invalid object field: $fieldName');
}

String _text(dynamic value) => value?.toString().trim() ?? '';

String? _nullableText(dynamic value) {
  final result = _text(value);
  return result.isEmpty ? null : result;
}
