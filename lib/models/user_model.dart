class UserModel {
  String? uid;
  String? email;
  String? token;

  UserModel({
    this.email,
    this.token,
    this.uid,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    this.uid = json['uid'];
    this.email = json['email'];
    this.token = json['token'];
  }

  Map<String, dynamic> toJson() {
    return {
      "uid": this.uid,
      "email": this.email,
      "token": this.token,
    };
  }
}
