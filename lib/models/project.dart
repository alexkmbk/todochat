class Project {
  int ID = 0;
  String Description = "";
  bool editMode = false;
  bool isNewItem = false;

  Project(
      {this.ID = 0,
      this.Description = "",
      this.editMode = false,
      this.isNewItem = false});

  Map<String, dynamic> toJson() {
    return {
      'ID': ID,
      'Description': Description,
    };
  }

  bool get isEmpty => ID == 0;
  bool get isNotEmpty => !isEmpty;

  factory Project.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Project();
    }
    return Project(
      ID: json['ID'] ?? 0,
      Description: json['Description'] ?? '',
    );
  }

  Project.from(Project project)
      : ID = project.ID,
        Description = project.Description;
}
