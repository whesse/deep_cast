# Introduction

json_cast is a package that casts the lists and maps in a JSON object from
List<dynamic> and Map<String, dynamic> to more specific types.

It uses a template literal, which can just be a sample of the JSON data,
to create the maps and lists of the correct types and fill them with data.
Optional parameters can make this template more efficient and powerful.


## Examples

The json object


```
{
  'version': '2.0.1',
  'owners': [
    'dart',
    'flutter',
    'web' ],
  'changed_fields': [
    {
      'name': 'foo',
      'from': '13',
      'to': '14'
    }],
  'deleted_fields': [
    { 'name': 'bar' },
    { 'name': 'baz' }]
}
```
can be converted to a Dart object with typed maps and lists with either of the templates
```
template1() => {
  'version': '2.0.1',
  'owners': ['dart',],
  '*': [{'name': 'foo'}],
}

template2() => <String, dynamic>{
   'owners': <String>[],
   '*': [<String, String>{}]
}
```

The Map and List objects in the object literal created by the template are
strongly typed by the Dart compiler when the template function is compiled,
based on the contained data or on explicit type arguments. When the template
is applied to a JSON object, the collections in the JSON object are replaced by
typed collections from the equivalent place in the template object. Wildcard
keys can be used in the template maps to match any entry in the JSON map.

In the example, the 'version' key or an explicit type annotation is needed
at the top level of the template, otherwise the top-level map in the template
would be inferred
by the compiler to be a Map<String, List>, since the other two entries are lists.
Then the 'version' entry in the actual JSON data could not be stored in it.

### Scalar values are ignored

Any scalar values in the template are ignored, and any scalar values in the JSON
data are left unchanged.  Only instances of Map and List in the JSON value are
copied into new typed instances, and only if those locations are in the template.
An exception is if the template contains a special constructor at that location.
Then that constructor is run unconditionally on the JSON value at that location.

### Breaking a template into pieces for efficiency

Because each new typed instance of Map or Literal is created by calling the template
function to create the template literal, jsonCast() can create many extra unused
objects. To avoid this, part of the template can be broken out, and passed as an
additional template function at the correct location in a second template.

The first template is replaced with this other template function when jsonCast
has descended recursively into this location in the object, and the new template
controls what happens in that subtree.  An example is:

```
object = [{
  'foo': [ [1], [2], [3] ],
  'bar': {'name': ['I', 'me', 'myself'] }
}];

template() => [{
  'foo': <List<int>>[],
  'bar': {}
}];

constructor = [{
  'foo': [()=> <int>[]],
  'bar': () => {'*': <String>[]}
}];

constructors = [constructor];

typedObject = jsonCast(object, template, constructors: constructors);
```

The types of the collections in the constructor literal do not matter.
The functions in the constructor literal replace the template function when
jsonCast has descended to that position in the object.  Therefore, there
cannot be a constructor function within another constructor function (the 
types in the outer constructure function's literal would not be correct).
If you want a special constructor for a location below another location
with a special constructor, you can construct a second constructor literal
with the other constructor at the desired location, and include it in the list
of objects in the constructors argument:
```
constructors = [
  {'bigvalue': ()=>[{'*': []}},
  {'bigvalue': [{'foo': [() => [1]]}]],
];
```

That example would not give a big performance improvement with the first
constructor, though. It will only be significantly faster to break a template into
pieces using constructors if the template is large, and contains a subcollection
that contains a large number of non-scalar entries.

### Custom classes from JSON
The constructors argument can also include constructors with a single input
parameter, which will be passed the JSON subobject at that location, and produce
an object which will replace it at that location in the JSON object being cast:
```
[{'timestamp': (date) => DateTime.parse(date)}]

{'objects': [ 
    (object) => { for (final field in object['fields']) 
         field['name']: field['intValue'] ?? field['stringValue'] }
]}
```

Although this capability can do quite general computation, and the constructor
could even have static state that computes a summary, jsonCast will always
be rebuilding the entire object tree down to that subtree, and so should not
be used instead of hand-coded iteration unless the type cast is desired.
