import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:code_builder/code_builder.dart';
import 'package:nuvigator/builder/base_builder.dart';

import 'helpers.dart';

class NavigationClass extends BaseBuilder {
  NavigationClass(ClassElement classElement) : super(classElement);

  Constructor _constructor() {
    return Constructor(
      (c) => c
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'nuvigator'
              ..toThis = true,
          ),
        ),
    );
  }

  Field _nuvigatorStateField() {
    return Field(
      (f) => f
        ..name = 'nuvigator'
        ..type = refer('NuvigatorState')
        ..modifier = FieldModifier.final$,
    );
  }

  Method _navigationMethod(String typeName) {
    return Method(
      (f) => f
        ..name = '${lowerCamelCase(typeName)}Navigation'
        ..returns = refer('${typeName}Navigation')
        ..type = MethodType.getter
        ..lambda = true
        ..body = Code(
          '${typeName}Navigation(nuvigator)',
        ),
    );
  }

  Method _ofMethod(String className) {
    return Method(
      (m) => m
        ..name = 'of'
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'context'
              ..type = refer('BuildContext'),
          ),
        )
        ..returns = refer(className)
        ..body = Code('$className(Nuvigator.of(context))')
        ..lambda = true
        ..static = true,
    );
  }

  Method _pushMethod(String className, String fieldName, String screenReturn,
      Map<DartObject, DartObject> args) {
    final parameters = <Parameter>[];
    final argumentsMapBuffer = StringBuffer('{');

    if (args != null) {
      for (final arg in args.entries) {
        final argName = arg.key.toStringValue();
        parameters.add(
          Parameter(
            (p) => p
              ..name = arg.key.toStringValue()
              ..named = true
              ..type = refer(
                arg.value.toTypeValue().name,
              ),
          ),
        );
        argumentsMapBuffer.write("'$argName': $argName,");
      }
    }
    argumentsMapBuffer.write('}');

    return Method(
      (m) => m
        ..name = fieldName
        ..returns = refer('Future<$screenReturn>')
        ..optionalParameters.addAll(parameters)
        ..body = args != null
            ? Code(
                'return nuvigator.pushNamed<$screenReturn>(${className}Routes.$fieldName, arguments: ${argumentsMapBuffer.toString()});',
              )
            : Code(
                'return nuvigator.pushNamed<$screenReturn>(${className}Routes.$fieldName);',
              ),
    );
  }

  Method _subRouteMethod(String className) {
    return Method(
      (m) => m
        ..name = '${lowerCamelCase(className)}Navigation'
        ..returns = refer('${className}Navigation')
        ..type = MethodType.getter
        ..lambda = true
        ..body = Code(
          '${className}Navigation(nuvigator)',
        ),
    );
  }

  Class _generateNavigationClass(String className, List<Method> methods) {
    return Class(
      (b) => b
        ..name = '${className}Navigation'
        ..constructors.add(_constructor())
        ..fields.add(_nuvigatorStateField())
        ..methods.addAll(
          [
            _ofMethod('${className}Navigation'),
            ...methods,
          ],
        ),
    );
  }

  @override
  Spec build() {
    final className = classElement.name;
    final methods = <Method>[];

    for (var field in classElement.fields) {
      final nuRouteFieldAnnotation =
          nuRouteChecker.firstAnnotationOf(field, throwOnUnresolved: true);
      final isFlow = field.type.name == 'FlowRoute';
      final nuSubRouterAnnotation =
          nuRouterChecker.firstAnnotationOfExact(field);

      if (nuRouteFieldAnnotation != null) {
        final generics = getGenericTypes(field.type);
        final args = nuRouteFieldAnnotation?.getField('args')?.toMapValue();
        final screenReturn =
            generics.length > 1 ? generics[1].name : generics.first.name;

        methods.add(
          _pushMethod(className, field.name, screenReturn, args),
        );

        if (isFlow) {
          final subRouter = getGenericTypes(field.type).first;
          methods.add(
            _subRouteMethod(subRouter.name),
          );
        }
      } else if (nuSubRouterAnnotation != null) {
        methods.add(
          _navigationMethod(field.type.name),
        );
      }
    }

    return _generateNavigationClass(className, methods);
  }
}
