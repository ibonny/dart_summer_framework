import '../lib/summer.dart';

class SomeClass {
  String first;
  String second;

  SomeClass([this.first, this.second]);

  Map toJson() {
    return {"first": first, "second": second};
  }
}

@Controller
class SampleController {
  @GetMapping("/")
  String indexRoute() {
    return "OK, we got it.";
  }

  @GetMapping("/blah")
  Map blahRoute() {
    return SomeClass("first", "second").toJson();
  }
}

void main(List<String> args) {
  Summer.run();
}
