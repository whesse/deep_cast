import 'dart:convert';

import 'package:test/test.dart';

import 'package:deep_cast/deep_cast.dart';

void main() {
  test('Map with two types of entries', () async {
    final list =
        json.decode('[{"bar":[1,2,3],"foo":{"name":"me","operator":"??="}}]');
    template() => [
          {
            '*': <int>[],
            'foo': <String, String>{},
          }
        ];
    final typed = deepCast(list, template);
    expect(typed, isA<List<Map<String, Object>>>());
    expect(typed.first, isA<Map<String, Object>>());
    expect(typed.first['bar'], isA<List<int>>());
    expect(typed.first['foo'], isA<Map<String, String>>());
  });

  test('Constructor for list', () async {
    final list = [
      [
        [
          [1, 2],
          [3]
        ],
        [
          [4],
          []
        ]
      ],
      [[]],
      []
    ];
    template() => [
          [
            [<int>[]]
          ]
        ];
    final constructor = [
      [
        () => [<int>[]]
      ]
    ];
    final constructors = [constructor];
    final typed = deepCast(list, template, constructors: constructors);
    expect(typed, list);
    expect(typed, isA<List<List<List<List<int>>>>>());

    templateShort() => [<List<List<int>>>[]];
    final typedShort =
        deepCast(list, templateShort, constructors: constructors);
    expect(typedShort, list);
    expect(typedShort, isA<List<List<List<List<int>>>>>());

    templateWider() => [
          <List>[
            <List<int>>[[]]
          ]
        ];
    final typedWider = deepCast(list, templateWider);
    expect(typedWider, list);
    expect(typedWider, isA<List<List<List>>>());
    expect(typedWider, isNot(isA<List<List<List<List>>>>()));
    expect(typedWider.first.first, isA<List<List<int>>>());
    typedWider.first.add(['b']);
    expect(() => typedWider.first.first.add('c'), throwsA(isA<TypeError>()));

    final typedWiderConstructor =
        deepCast(list, templateWider, constructors: constructors);
    expect(typedWiderConstructor, list);
    expect(typedWiderConstructor, isA<List<List<List>>>());
    expect(typedWiderConstructor, isNot(isA<List<List<List<List>>>>()));
    expect(typedWiderConstructor.first.first, isA<List<List<int>>>());
  });
}
