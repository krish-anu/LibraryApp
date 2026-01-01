class Failure {
  final String message;
  Failure([this.message = "Unexpected error occured"]);
}

class AppFailure extends Failure {
  AppFailure([super.message]);
}
