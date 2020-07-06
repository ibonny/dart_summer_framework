import 'dart:convert';

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
  SomeClass blahRoute() {
    return SomeClass("first", "second");
  }

  @PostMapping("/funtimes")
  String postMappingRequest(@RequestBody String content) {
    var data = jsonDecode(content) as Map;

    print(data);

    return "OK, we got this, too.";
  }

  @GetMapping("/anotherpart")
  String getAnotherPart() {
    return "OK, yep.";
  }
}

void main(List<String> args) {
  Summer.run("0.0.0.0", 4040);
}
