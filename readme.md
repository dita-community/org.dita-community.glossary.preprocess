# org.dita-community.glossary.preprocess Open Toolkit Plugin

Preprocessing extension that automates the generation and sorting of glossaries.

Extends the preprocess `keyref` phase. Modifies the resolved map to reflect the glossary manipulation options requested.

Recognizes the BookMap `glossarylist` element or the @outputclass "glossarylist" as the trigger for generating a glossary or as the container of a literal glossary. 

Recognizes `glossgroup` topics as containers of other glossary groups or glossary entries (normally via nested topicrefs). When glossary filtering is applied, `glossgroup` topics that end up with no child topicrefs are also filtered out.

Provides an extension point, `org.dita-community.glossary.preprocess.xsl`, for adding custom processing as needed, for example, to recognize elements other than `glosslist` as glossary containers or generation signalers. 

OT version: 3.3+

## Dependencies:

- org.dita-community.common.xslt
- org.dita-community.i18n
- org.dita.base

## Runtime parameters

  * dita-community.sort-glossary - Turns glossary sorting on or off
  * dita-community.filter-glossary - Turns glossary filtering on or off
  * dita-community.generate-glossary - Turns glossary generation on or off
  
Values are "on" or "off" or "true" or "false".

## Glossary Sorting

Option: `dita-community.sort-glossary=true`

Uses the `org.dita-community.i18n` locale-aware sorting and grouping functions to group and sort glossary entries based on the glossary term and any `sort-as` elements in glossary entry prologs. Provides dictionary-based sorting and grouping of Simplified Chinese, otherwise uses the collation and grouping configuration for the content's locale.

## Glossary Filtering

Option: `dita-community.filter-glossary=true`

Glossary filtering examines all normal-role, non-glossary-entry topics to find all links to `glossentry` topics and then all links from those glossary entries to other glossary entries, resulting in the minimun set of glossary entries needed to satisfy all glossary links emenating from the normal-role, non-glossary entry topics.

The resulting glossary navigation structure then reflects only those glossary entries actually used. Any `glossgroup` topics that end up with no descendant glossary entries are also filtered out.

The filtering result is the same whether the glossary is generated or literally authored.

## Glossary generation

Option: `dita-community.generate-glossary=true`

NOTE: glossary generation implies glossary sorting.

For documents that have resource-only topicrefs to glossary entries and have an empty `glossarylist` element or topicref with an outputclass of "glossarylsit", a glossary is generated at the point where `glossarylist` occurs. Literal normal-role topicrefs to glossary entries are not affected.

The processor finds all resource-only topicrefs to `glossentry` topics then groups and sorts them as described under "Glossary Sorting". This ensures that all keyrefs to glossary entries will continue to be resolved correctly.

Each resource-only topicref to a glossary entry is removed from its original location, changed to a normal-role topicref, and placed in the generated glossary navigation structure that results from the grouping and sorting process.

If filtering is also turned on, the resulting glossary is filtered as described under "Glossary Filtering", otherwise the glossary reflects all glossary entries found by examining all the resource-only topicrefs in the map.

Use the `org.dita-community.glossary.preprocess.xsl` to add support for whatever markup convention is used to signal the place where the glossary should be generated if the base processing is not sufficient.



