import "dart:convert";

typedef dynamic Constructor();

dynamic deepCast(dynamic object, Constructor templateFunction,
    {List<dynamic> constructors = const [],
    String keyWildcard = '*',
    dynamic templateInstance}) {
  if (object is Map<String, dynamic>) {
    final result = templateFunction();
    if (object.isEmpty) {
      return result..clear();
    }

    Map<String, dynamic> template = templateInstance ?? templateFunction();
    if (template is Map<String, dynamic>) {
      for (final key in object.keys) {
        Constructor? valueConstructor;
        var valueTemplate;
        final valueConstructors = [
          for (Map constructor in constructors)
            if (constructor.containsKey(key)) constructor[key]
        ];
        valueConstructor = valueConstructors.firstWhere(
            (constructor) => constructor is Constructor,
            orElse: () => null);
        if (valueConstructor != null) {
          valueConstructors.remove(valueConstructor);
          valueTemplate = valueConstructor();
        } else if (template[key] is Map || template[key] is List) {
          valueConstructor = () => templateFunction()[key];
          valueTemplate = template[key];
        } else if (template[keyWildcard] is Map ||
            template[keyWildcard] is List) {
          valueConstructor = () => templateFunction()[keyWildcard];
          valueTemplate = template[keyWildcard];
        }

        result[key] = valueConstructor != null
            ? deepCast(object[key], valueConstructor,
                templateInstance: valueTemplate)
            : object[key];
      }
      return result;
    } else {
      // throwMismatch(template.runtimeType, object.runtimeType);
    }
  } else if (object is List) {
    final List<dynamic> result = templateFunction();
    if (object.isEmpty) {
      return result..clear();
    }
    if (result.isEmpty && constructors.isEmpty) {
      for (final item in object) {
        result.add(item);
      }
      return result;
    }
    late final valueTemplate;
    late final Constructor valueConstructor;
    final valueConstructors = [
      for (List constructor in constructors) constructor.first
    ];
    final newConstructor = valueConstructors.firstWhere(
        (constructor) => constructor is Function,
        orElse: () => null);
    if (newConstructor != null) {
      valueConstructors.remove(newConstructor);
      valueConstructor = newConstructor;
      valueTemplate = newConstructor();
    } else {
      valueConstructor = () => templateFunction().first;
      valueTemplate = result.first;
    }
    result.clear();
    for (final value in object) {
      result.add(deepCast(
        value,
        valueConstructor,
        constructors: valueConstructors,
        templateInstance: valueTemplate,
      ));
    }
    return result;
  } else
    return object;
}
