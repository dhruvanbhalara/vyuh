import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vyuh_core/vyuh_core.dart';
import 'package:vyuh_extension_content/vyuh_extension_content.dart';
import 'package:vyuh_feature_system/vyuh_feature_system.dart';

part 'conditional.g.dart';

@JsonSerializable()
class Conditional extends ContentItem {
  static const schemaName = 'vyuh.conditional';

  @JsonKey(defaultValue: [])
  final List<CaseItem>? cases;

  final String? defaultCase;
  final Condition? condition;

  Conditional({this.cases, this.condition, this.defaultCase})
      : super(schemaType: Conditional.schemaName);

  factory Conditional.fromJson(Map<String, dynamic> json) =>
      _$ConditionalFromJson(json);

  Future<ContentItem?> execute() async {
    final value = (await condition?.execute()) ?? defaultCase;

    final caseItem =
        cases?.firstWhereOrNull((element) => element.value == value);

    return caseItem?.item;
  }
}

@JsonSerializable()
final class CaseItem<T extends SchemaItem> {
  final String? value;

  @JsonKey(fromJson: typeFromFirstOfListJson<ContentItem>)
  final ContentItem? item;

  CaseItem({this.value, this.item});

  factory CaseItem.fromJson(Map<String, dynamic> json) =>
      _$CaseItemFromJson(json);
}

class ConditionalDescriptor extends ContentDescriptor {
  ConditionalDescriptor({super.layouts})
      : super(schemaType: Conditional.schemaName, title: 'Conditional');
}

final class ConditionalContentBuilder extends ContentBuilder<Conditional> {
  ConditionalContentBuilder()
      : super(
          content: TypeDescriptor(
              schemaType: Conditional.schemaName,
              title: 'Conditional',
              fromJson: Conditional.fromJson),
          defaultLayout: DefaultConditionalLayout(),
          defaultLayoutDescriptor: DefaultConditionalLayout.typeDescriptor,
        );
}

final class DefaultConditionalLayout extends LayoutConfiguration<Conditional> {
  static const schemaName = '${Conditional.schemaName}.layout.default';
  static final typeDescriptor = TypeDescriptor(
    schemaType: schemaName,
    title: 'Default Conditional Layout',
    fromJson: DefaultConditionalLayout.fromJson,
  );

  DefaultConditionalLayout() : super(schemaType: schemaName);

  factory DefaultConditionalLayout.fromJson(Map<String, dynamic> json) =>
      DefaultConditionalLayout();

  @override
  Widget build(BuildContext context, Conditional content) =>
      _ConditionalBuilder(conditional: content);
}

class _ConditionalBuilder extends StatelessWidget {
  final Conditional conditional;

  const _ConditionalBuilder({required this.conditional});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: conditional.execute(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done || ConnectionState.active:
              final item = snapshot.data;
              return item == null
                  ? empty
                  : vyuh.content.buildContent(context, item);

            default:
              return vyuh.widgetBuilder.contentLoader();
          }
        });
  }
}
