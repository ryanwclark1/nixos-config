{
  ...
}:
let
  base00 = "303446"; # base
  base01 = "292c3c"; # mantle
  base02 = "414559"; # surface0
  base03 = "51576d"; # surface1
  base04 = "626880"; # surface2
  base05 = "c6d0f5"; # text
  base06 = "f2d5cf"; # rosewater
  base07 = "babbf1"; # lavender
  base08 = "e78284"; # red
  base09 = "ef9f76"; # peach
  base0A = "e5c890"; # yellow
  base0B = "a6d189"; # green
  base0C = "81c8be"; # teal
  base0D = "8caaee"; # blue
  base0E = "ca9ee6"; # mauve
  base0F = "eebebe"; # flamingo
  base10 = "292c3c"; # mantle - darker background
  base11 = "232634"; # crust - darkest background
  base12 = "ea999c"; # maroon - bright red
  base13 = "f2d5cf"; # rosewater - bright yellow
  base14 = "a6d189"; # green - bright green
  base15 = "99d1db"; # sky - bright cyan
  base16 = "85c1dc"; # sapphire - bright blue
  base17 = "f4b8e4"; # pink - bright purple
in
{
  home.file.".config/bat/themes/theme.tmTheme" = {
    text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>name</key>
        <string>Theme</string>
        <key>semanticClass</key>
        <string>theme</string>
        <key>uuid</key>
        <string>e0ada983-8938-490c-86f0-97a1a0ec58e4</string>
        <key>author</key>
        <string></string>
        <key>colorSpaceName</key>
        <string>sRGB</string>
        <key>settings</key>
        <array>
          <dict>
            <key>settings</key>
            <dict>
              <key>background</key>
              <string>#${base00}</string>
              <key>foreground</key>
              <string>#${base05}</string>
              <key>caret</key>
              <string>#${base06}</string>
              <key>lineHighlight</key>
              <string>#${base02}</string>
              <key>misspelling</key>
              <string>#${base08}</string>
              <key>accent</key>
              <string>#${base0E}</string>
              <key>selection</key>
              <string>#949cbb40</string>
              <key>activeGuide</key>
              <string>#${base03}</string>
              <key>findHighlight</key>
              <string>#506373</string>
              <key>gutterForeground</key>
              <string>#838ba7</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Basic text &amp; variable names (incl. leading punctuation)</string>
            <key>scope</key>
            <string>text, source, variable.other.readwrite, punctuation.definition.variable</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Parentheses, Brackets, Braces</string>
            <key>scope</key>
            <string>punctuation</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#949cbb</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Comments</string>
            <key>scope</key>
            <string>comment, punctuation.definition.comment</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#737994</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>string, punctuation.definition.string</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0B}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>constant.character.escape</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Booleans, constants, numbers</string>
            <key>scope</key>
            <string>constant.numeric, variable.other.constant, entity.name.constant, constant.language.boolean, constant.language.false, constant.language.true, keyword.other.unit.user-defined, keyword.other.unit.suffix.floating-point</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>keyword, keyword.operator.word, keyword.operator.new, variable.language.super, support.type.primitive, storage.type, storage.modifier, punctuation.definition.keyword</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>entity.name.tag.documentation</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Punctuation</string>
            <key>scope</key>
            <string>keyword.operator, punctuation.accessor, punctuation.definition.generic, meta.function.closure punctuation.section.parameters, punctuation.definition.tag, punctuation.separator.key-value</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>entity.name.function, meta.function-call.method, support.function, support.function.misc, variable.function</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Classes</string>
            <key>scope</key>
            <string>entity.name.class, entity.other.inherited-class, support.class, meta.function-call.constructor, entity.name.struct</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Enum</string>
            <key>scope</key>
            <string>entity.name.enum</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Enum member</string>
            <key>scope</key>
            <string>meta.enum variable.other.readwrite, variable.other.enummember</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Object properties</string>
            <key>scope</key>
            <string>meta.property.object</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Types</string>
            <key>scope</key>
            <string>meta.type, meta.type-alias, support.type, entity.name.type</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Decorators</string>
            <key>scope</key>
            <string>meta.annotation variable.function, meta.annotation variable.annotation.function, meta.annotation punctuation.definition.annotation, meta.decorator, punctuation.decorator</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>variable.parameter, meta.function.parameters</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base12}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Built-ins</string>
            <key>scope</key>
            <string>constant.language, support.function.builtin</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base08}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>entity.other.attribute-name.documentation</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base08}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Preprocessor directives</string>
            <key>scope</key>
            <string>keyword.control.directive, punctuation.definition.directive</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Type parameters</string>
            <key>scope</key>
            <string>punctuation.definition.typeparameters</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base15}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Namespaces</string>
            <key>scope</key>
            <string>entity.name.namespace</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Property names (left hand assignments in json/yaml/css)</string>
            <key>scope</key>
            <string>support.type.property-name.css</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>This/Self keyword</string>
            <key>scope</key>
            <string>variable.language.this, variable.language.this punctuation.definition.variable</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base08}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Object properties</string>
            <key>scope</key>
            <string>variable.object.property</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>String template interpolation</string>
            <key>scope</key>
            <string>string.template variable, string variable</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>`new` as bold</string>
            <key>scope</key>
            <string>keyword.operator.new</string>
            <key>settings</key>
            <dict>
              <key>fontStyle</key>
              <string>bold</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>C++ extern keyword</string>
            <key>scope</key>
            <string>storage.modifier.specifier.extern.cpp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>C++ scope resolution</string>
            <key>scope</key>
            <string>entity.name.scope-resolution.template.call.cpp, entity.name.scope-resolution.parameter.cpp, entity.name.scope-resolution.cpp, entity.name.scope-resolution.function.definition.cpp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>C++ doc keywords</string>
            <key>scope</key>
            <string>storage.type.class.doxygen</string>
            <key>settings</key>
            <dict>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>C++ operators</string>
            <key>scope</key>
            <string>storage.modifier.reference.cpp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>C# Interpolated Strings</string>
            <key>scope</key>
            <string>meta.interpolation.cs</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>C# xml-style docs</string>
            <key>scope</key>
            <string>comment.block.documentation.cs</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Classes, reflecting the className color in JSX</string>
            <key>scope</key>
            <string>source.css entity.other.attribute-name.class.css, entity.other.attribute-name.parent-selector.css punctuation.definition.entity.css</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Operators</string>
            <key>scope</key>
            <string>punctuation.separator.operator.css</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Pseudo classes</string>
            <key>scope</key>
            <string>source.css entity.other.attribute-name.pseudo-class</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>source.css constant.other.unicode-range</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>source.css variable.parameter.url</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0B}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>CSS vendored property names</string>
            <key>scope</key>
            <string>support.type.vendored.property-name</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base15}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Less/SCSS right-hand variables (@/$-prefixed)</string>
            <key>scope</key>
            <string>source.css meta.property-value variable, source.css meta.property-value variable.other.less, source.css meta.property-value variable.other.less punctuation.definition.variable.less, meta.definition.variable.scss</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base12}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>CSS variables (--prefixed)</string>
            <key>scope</key>
            <string>source.css meta.property-list variable, meta.property-list variable.other.less, meta.property-list variable.other.less punctuation.definition.variable.less</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>CSS Percentage values, styled the same as numbers</string>
            <key>scope</key>
            <string>keyword.other.unit.percentage.css</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>CSS Attribute selectors, styled the same as strings</string>
            <key>scope</key>
            <string>source.css meta.attribute-selector</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0B}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>JSON/YAML keys, other left-hand assignments</string>
            <key>scope</key>
            <string>keyword.other.definition.ini, punctuation.support.type.property-name.json, support.type.property-name.json, punctuation.support.type.property-name.toml, support.type.property-name.toml, entity.name.tag.yaml, punctuation.support.type.property-name.yaml, support.type.property-name.yaml</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>JSON/YAML constants</string>
            <key>scope</key>
            <string>constant.language.json, constant.language.yaml</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>YAML anchors</string>
            <key>scope</key>
            <string>entity.name.type.anchor.yaml, variable.other.alias.yaml</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>TOML tables / ini groups</string>
            <key>scope</key>
            <string>support.type.property-name.table, entity.name.section.group-title.ini</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>TOML dates</string>
            <key>scope</key>
            <string>constant.other.time.datetime.offset.toml</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>YAML anchor puctuation</string>
            <key>scope</key>
            <string>punctuation.definition.anchor.yaml, punctuation.definition.alias.yaml</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>YAML triple dashes</string>
            <key>scope</key>
            <string>entity.other.document.begin.yaml</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markup Diff</string>
            <key>scope</key>
            <string>markup.changed.diff</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Diff</string>
            <key>scope</key>
            <string>meta.diff.header.from-file, meta.diff.header.to-file, punctuation.definition.from-file.diff, punctuation.definition.to-file.diff</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Diff Inserted</string>
            <key>scope</key>
            <string>markup.inserted.diff</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0B}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Diff Deleted</string>
            <key>scope</key>
            <string>markup.deleted.diff</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base08}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>dotenv left-hand side assignments</string>
            <key>scope</key>
            <string>variable.other.env</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>dotenv reference to existing env variable</string>
            <key>scope</key>
            <string>string.quoted variable.other.env</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>GDScript functions</string>
            <key>scope</key>
            <string>support.function.builtin.gdscript</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>GDScript constants</string>
            <key>scope</key>
            <string>constant.language.gdscript</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Comment keywords</string>
            <key>scope</key>
            <string>comment meta.annotation.go</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base12}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>go:embed, go:build, etc.</string>
            <key>scope</key>
            <string>comment meta.annotation.parameters.go</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Go constants (nil, true, false)</string>
            <key>scope</key>
            <string>constant.language.go</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>GraphQL variables</string>
            <key>scope</key>
            <string>variable.graphql</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>GraphQL aliases</string>
            <key>scope</key>
            <string>string.unquoted.alias.graphql</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0F}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>GraphQL enum members</string>
            <key>scope</key>
            <string>constant.character.enum.graphql</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>GraphQL field in types</string>
            <key>scope</key>
            <string>meta.objectvalues.graphql constant.object.key.graphql string.unquoted.graphql</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0F}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>HTML/XML DOCTYPE as keyword</string>
            <key>scope</key>
            <string>keyword.other.doctype, meta.tag.sgml.doctype punctuation.definition.tag, meta.tag.metadata.doctype entity.name.tag, meta.tag.metadata.doctype punctuation.definition.tag</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>HTML/XML-like &lt;tags/&gt;</string>
            <key>scope</key>
            <string>entity.name.tag</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Special characters like &amp;amp;</string>
            <key>scope</key>
            <string>text.html constant.character.entity, text.html constant.character.entity punctuation, constant.character.entity.xml, constant.character.entity.xml punctuation, constant.character.entity.js.jsx, constant.charactger.entity.js.jsx punctuation, constant.character.entity.tsx, constant.character.entity.tsx punctuation</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base08}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>HTML/XML tag attribute values</string>
            <key>scope</key>
            <string>entity.other.attribute-name</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Components</string>
            <key>scope</key>
            <string>support.class.component, support.class.component.jsx, support.class.component.tsx, support.class.component.vue</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Annotations</string>
            <key>scope</key>
            <string>punctuation.definition.annotation, storage.type.annotation</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Java enums</string>
            <key>scope</key>
            <string>constant.other.enum.java</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Java imports</string>
            <key>scope</key>
            <string>storage.modifier.import.java</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Javadoc</string>
            <key>scope</key>
            <string>comment.block.javadoc.java keyword.other.documentation.javadoc.java</string>
            <key>settings</key>
            <dict>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Exported Variable</string>
            <key>scope</key>
            <string>meta.export variable.other.readwrite.js</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base12}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>JS/TS constants &amp; properties</string>
            <key>scope</key>
            <string>variable.other.constant.js, variable.other.constant.ts, variable.other.property.js, variable.other.property.ts</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>JSDoc; these are mainly params, so styled as such</string>
            <key>scope</key>
            <string>variable.other.jsdoc, comment.block.documentation variable.other</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base12}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>JSDoc keywords</string>
            <key>scope</key>
            <string>storage.type.class.jsdoc</string>
            <key>settings</key>
            <dict>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>support.type.object.console.js</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Node constants as keywords (module, etc.)</string>
            <key>scope</key>
            <string>support.constant.node, support.type.object.module.js</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>implements as keyword</string>
            <key>scope</key>
            <string>storage.modifier.implements</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Builtin types</string>
            <key>scope</key>
            <string>constant.language.null.js, constant.language.null.ts, constant.language.undefined.js, constant.language.undefined.ts, support.type.builtin.ts</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>variable.parameter.generic</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Arrow functions</string>
            <key>scope</key>
            <string>keyword.declaration.function.arrow.js, storage.type.function.arrow.ts</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Decorator punctuations (decorators inherit from blue functions, instead of styleguide peach)</string>
            <key>scope</key>
            <string>punctuation.decorator.ts</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Extra JS/TS keywords</string>
            <key>scope</key>
            <string>keyword.operator.expression.in.js, keyword.operator.expression.in.ts, keyword.operator.expression.infer.ts, keyword.operator.expression.instanceof.js, keyword.operator.expression.instanceof.ts, keyword.operator.expression.is, keyword.operator.expression.keyof.ts, keyword.operator.expression.of.js, keyword.operator.expression.of.ts, keyword.operator.expression.typeof.ts</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Julia macros</string>
            <key>scope</key>
            <string>support.function.macro.julia</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Julia language constants (true, false)</string>
            <key>scope</key>
            <string>constant.language.julia</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Julia other constants (these seem to be arguments inside arrays)</string>
            <key>scope</key>
            <string>constant.other.symbol.julia</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base12}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>LaTeX preamble</string>
            <key>scope</key>
            <string>text.tex keyword.control.preamble</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>LaTeX be functions</string>
            <key>scope</key>
            <string>text.tex support.function.be</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base15}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>LaTeX math</string>
            <key>scope</key>
            <string>constant.other.general.math.tex</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0F}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Lua docstring keywords</string>
            <key>scope</key>
            <string>comment.line.double-dash.documentation.lua storage.type.annotation.lua</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Lua docstring variables</string>
            <key>scope</key>
            <string>comment.line.double-dash.documentation.lua entity.name.variable.lua, comment.line.double-dash.documentation.lua variable.lua</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>heading.1.markdown punctuation.definition.heading.markdown, heading.1.markdown, markup.heading.atx.1.mdx, markup.heading.atx.1.mdx punctuation.definition.heading.mdx, markup.heading.setext.1.markdown, markup.heading.heading-0.asciidoc</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base08}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>heading.2.markdown punctuation.definition.heading.markdown, heading.2.markdown, markup.heading.atx.2.mdx, markup.heading.atx.2.mdx punctuation.definition.heading.mdx, markup.heading.setext.2.markdown, markup.heading.heading-1.asciidoc</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>heading.3.markdown punctuation.definition.heading.markdown, heading.3.markdown, markup.heading.atx.3.mdx, markup.heading.atx.3.mdx punctuation.definition.heading.mdx, markup.heading.heading-2.asciidoc</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>heading.4.markdown punctuation.definition.heading.markdown, heading.4.markdown, markup.heading.atx.4.mdx, markup.heading.atx.4.mdx punctuation.definition.heading.mdx, markup.heading.heading-3.asciidoc</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0B}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>heading.5.markdown punctuation.definition.heading.markdown, heading.5.markdown, markup.heading.atx.5.mdx, markup.heading.atx.5.mdx punctuation.definition.heading.mdx, markup.heading.heading-4.asciidoc</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>heading.6.markdown punctuation.definition.heading.markdown, heading.6.markdown, markup.heading.atx.6.mdx, markup.heading.atx.6.mdx punctuation.definition.heading.mdx, markup.heading.heading-5.asciidoc</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>markup.bold</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base08}</string>
              <key>fontStyle</key>
              <string>bold</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>markup.italic</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base08}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>markup.strikethrough</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#a5adce</string>
              <key>fontStyle</key>
              <string>strikethrough</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markdown auto links</string>
            <key>scope</key>
            <string>punctuation.definition.link, markup.underline.link</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markdown links</string>
            <key>scope</key>
            <string>text.html.markdown punctuation.definition.link.title, string.other.link.title.markdown, markup.link, punctuation.definition.constant.markdown, constant.other.reference.link.markdown, markup.substitution.attribute-reference</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base07}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markdown code spans</string>
            <key>scope</key>
            <string>punctuation.definition.raw.markdown, markup.inline.raw.string.markdown, markup.raw.block.markdown</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0B}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markdown triple backtick language identifier</string>
            <key>scope</key>
            <string>fenced_code.block.language</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base15}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markdown triple backticks</string>
            <key>scope</key>
            <string>markup.fenced_code.block punctuation.definition, markup.raw support.asciidoc</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#949cbb</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markdown quotes</string>
            <key>scope</key>
            <string>markup.quote, punctuation.definition.quote.begin</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markdown separators</string>
            <key>scope</key>
            <string>meta.separator.markdown</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markdown list bullets</string>
            <key>scope</key>
            <string>punctuation.definition.list.begin.markdown, markup.list.bullet</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Nix attribute names</string>
            <key>scope</key>
            <string>entity.other.attribute-name.multipart.nix, entity.other.attribute-name.single.nix</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Nix parameter names</string>
            <key>scope</key>
            <string>variable.parameter.name.nix</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Nix interpolated parameter names</string>
            <key>scope</key>
            <string>meta.embedded variable.parameter.name.nix</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base07}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Nix paths</string>
            <key>scope</key>
            <string>string.unquoted.path.nix</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>PHP Attributes</string>
            <key>scope</key>
            <string>support.attribute.builtin, meta.attribute.php</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>PHP Parameters (needed for the leading dollar sign)</string>
            <key>scope</key>
            <string>meta.function.parameters.php punctuation.definition.variable.php</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base12}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>PHP Constants (null, __FILE__, etc.)</string>
            <key>scope</key>
            <string>constant.language.php</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>PHP functions</string>
            <key>scope</key>
            <string>text.html.php support.function</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base15}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>PHPdoc keywords</string>
            <key>scope</key>
            <string>keyword.other.phpdoc.php</string>
            <key>settings</key>
            <dict>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Python argument functions reset to text, otherwise they inherit blue from function-call</string>
            <key>scope</key>
            <string>support.variable.magic.python, meta.function-call.arguments.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Python double underscore functions</string>
            <key>scope</key>
            <string>support.function.magic.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base15}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Python `self` keyword</string>
            <key>scope</key>
            <string>variable.parameter.function.language.special.self.python, variable.language.special.self.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base08}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>python keyword flow/logical (for ... in)</string>
            <key>scope</key>
            <string>keyword.control.flow.python, keyword.operator.logical.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>python storage type</string>
            <key>scope</key>
            <string>storage.type.function.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>python function support</string>
            <key>scope</key>
            <string>support.token.decorator.python, meta.function.decorator.identifier.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base15}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>python function calls</string>
            <key>scope</key>
            <string>meta.function-call.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>python function decorators</string>
            <key>scope</key>
            <string>entity.name.function.decorator.python, punctuation.definition.decorator.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>python placeholder reset to normal string</string>
            <key>scope</key>
            <string>constant.character.format.placeholder.other.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Python exception &amp; builtins such as exit()</string>
            <key>scope</key>
            <string>support.type.exception.python, support.function.builtin.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>entity.name.type</string>
            <key>scope</key>
            <string>support.type.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>python constants (True/False)</string>
            <key>scope</key>
            <string>constant.language.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Arguments accessed later in the function body</string>
            <key>scope</key>
            <string>meta.indexed-name.python, meta.item-access.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base12}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Python f-strings/binary/unicode storage types</string>
            <key>scope</key>
            <string>storage.type.string.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0B}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Python type hints</string>
            <key>scope</key>
            <string>meta.function.parameters.python</string>
            <key>settings</key>
            <dict>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Regex string begin/end in JS/TS</string>
            <key>scope</key>
            <string>string.regexp punctuation.definition.string.begin, string.regexp punctuation.definition.string.end</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Regex anchors (^, $)</string>
            <key>scope</key>
            <string>keyword.control.anchor.regexp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Regex regular string match</string>
            <key>scope</key>
            <string>string.regexp.ts</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Regex group parenthesis &amp; backreference (\1, \2, \3, ...)</string>
            <key>scope</key>
            <string>punctuation.definition.group.regexp, keyword.other.back-reference.regexp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0B}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Regex character class []</string>
            <key>scope</key>
            <string>punctuation.definition.character-class.regexp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Regex character classes (\d, \w, \s)</string>
            <key>scope</key>
            <string>constant.other.character-class.regexp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Regex range</string>
            <key>scope</key>
            <string>constant.other.character-class.range.regexp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base06}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Regex quantifier</string>
            <key>scope</key>
            <string>keyword.operator.quantifier.regexp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Regex constant/numeric</string>
            <key>scope</key>
            <string>constant.character.numeric.regexp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Regex lookaheads, negative lookaheads, lookbehinds, negative lookbehinds</string>
            <key>scope</key>
            <string>punctuation.definition.group.no-capture.regexp, meta.assertion.look-ahead.regexp, meta.assertion.negative-look-ahead.regexp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust attribute</string>
            <key>scope</key>
            <string>meta.annotation.rust, meta.annotation.rust punctuation, meta.attribute.rust, punctuation.definition.attribute.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust attribute strings</string>
            <key>scope</key>
            <string>meta.attribute.rust string.quoted.double.rust, meta.attribute.rust string.quoted.single.char.rust</string>
            <key>settings</key>
            <dict>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust keyword</string>
            <key>scope</key>
            <string>entity.name.function.macro.rules.rust, storage.type.module.rust, storage.modifier.rust, storage.type.struct.rust, storage.type.enum.rust, storage.type.trait.rust, storage.type.union.rust, storage.type.impl.rust, storage.type.rust, storage.type.function.rust, storage.type.type.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust u/i32, u/i64, etc.</string>
            <key>scope</key>
            <string>entity.name.type.numeric.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
              <key>fontStyle</key>
              <string/>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust generic</string>
            <key>scope</key>
            <string>meta.generic.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust impl</string>
            <key>scope</key>
            <string>entity.name.impl.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust module</string>
            <key>scope</key>
            <string>entity.name.module.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust trait</string>
            <key>scope</key>
            <string>entity.name.trait.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust struct</string>
            <key>scope</key>
            <string>storage.type.source.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust union</string>
            <key>scope</key>
            <string>entity.name.union.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust enum member</string>
            <key>scope</key>
            <string>meta.enum.rust storage.type.source.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust macro</string>
            <key>scope</key>
            <string>support.macro.rust, meta.macro.rust support.function.rust, entity.name.function.macro.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust lifetime</string>
            <key>scope</key>
            <string>storage.modifier.lifetime.rust, entity.name.type.lifetime</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust string formatting</string>
            <key>scope</key>
            <string>string.quoted.double.rust constant.other.placeholder.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust return type generic</string>
            <key>scope</key>
            <string>meta.function.return-type.rust meta.generic.rust storage.type.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust functions</string>
            <key>scope</key>
            <string>meta.function.call.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust angle brackets</string>
            <key>scope</key>
            <string>punctuation.brackets.angle.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base15}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust constants</string>
            <key>scope</key>
            <string>constant.other.caps.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust function parameters</string>
            <key>scope</key>
            <string>meta.function.definition.rust variable.other.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base12}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust closure variables</string>
            <key>scope</key>
            <string>meta.function.call.rust variable.other.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust self</string>
            <key>scope</key>
            <string>variable.language.self.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base08}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust metavariable names</string>
            <key>scope</key>
            <string>variable.other.metavariable.name.rust, meta.macro.metavariable.rust keyword.operator.macro.dollar.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Shell shebang</string>
            <key>scope</key>
            <string>comment.line.shebang, comment.line.shebang punctuation.definition.comment, comment.line.shebang, punctuation.definition.comment.shebang.shell, meta.shebang.shell</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Shell shebang command</string>
            <key>scope</key>
            <string>comment.line.shebang constant.language</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Shell interpolated command</string>
            <key>scope</key>
            <string>meta.function-call.arguments.shell punctuation.definition.variable.shell, meta.function-call.arguments.shell punctuation.section.interpolation, meta.function-call.arguments.shell punctuation.definition.variable.shell, meta.function-call.arguments.shell punctuation.section.interpolation</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base08}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Shell interpolated command variable</string>
            <key>scope</key>
            <string>meta.string meta.interpolation.parameter.shell variable.other.readwrite</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>source.shell punctuation.section.interpolation, punctuation.definition.evaluation.backticks.shell</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0C}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Shell EOF</string>
            <key>scope</key>
            <string>entity.name.tag.heredoc.shell</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Shell quoted variable</string>
            <key>scope</key>
            <string>string.quoted.double.shell variable.other.normal.shell</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Shell programming source</string>
            <key>scope</key>
            <string>programming.source.shell, source.shell</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>AppleScript programming source</string>
            <key>scope</key>
            <string>programming.source.applescript, source.applescript</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Configuration metadata</string>
            <key>scope</key>
            <string>text.configuration.metadata</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Executable library</string>
            <key>scope</key>
            <string>executable.library</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Lua programming source</string>
            <key>scope</key>
            <string>programming.source.lua, source.lua</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>OCaml programming source</string>
            <key>scope</key>
            <string>programming.source.ocaml, source.ocaml</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Haskell programming source</string>
            <key>scope</key>
            <string>programming.source.haskell, source.haskell</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Erlang programming source</string>
            <key>scope</key>
            <string>programming.source.erlang, source.erlang</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Elixir programming source</string>
            <key>scope</key>
            <string>programming.source.elixir, source.elixir</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Clojure programming source</string>
            <key>scope</key>
            <string>programming.source.clojure, source.clojure</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Scheme programming source</string>
            <key>scope</key>
            <string>programming.source.scheme, source.scheme</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Racket programming source</string>
            <key>scope</key>
            <string>programming.source.racket, source.racket</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>F# programming source</string>
            <key>scope</key>
            <string>programming.source.fsharp, source.fsharp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Scala programming source</string>
            <key>scope</key>
            <string>programming.source.scala, source.scala</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Kotlin programming source</string>
            <key>scope</key>
            <string>programming.source.kotlin, source.kotlin</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Dart programming source</string>
            <key>scope</key>
            <string>programming.source.dart, source.dart</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Julia programming source</string>
            <key>scope</key>
            <string>programming.source.julia, source.julia</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>R programming source</string>
            <key>scope</key>
            <string>programming.source.r, source.r</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>MATLAB programming source</string>
            <key>scope</key>
            <string>programming.source.matlab, source.matlab</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Fortran programming source</string>
            <key>scope</key>
            <string>programming.source.fortran, source.fortran</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Pascal programming source</string>
            <key>scope</key>
            <string>programming.source.pascal, source.pascal</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Assembly programming source</string>
            <key>scope</key>
            <string>programming.source.assembly, source.assembly</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Verilog programming source</string>
            <key>scope</key>
            <string>programming.source.verilog, source.verilog</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>VHDL programming source</string>
            <key>scope</key>
            <string>programming.source.vhdl, source.vhdl</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Prolog programming source</string>
            <key>scope</key>
            <string>programming.source.prolog, source.prolog</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Lisp programming source</string>
            <key>scope</key>
            <string>programming.source.lisp, source.lisp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Nim programming source</string>
            <key>scope</key>
            <string>programming.source.nim, source.nim</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Crystal programming source</string>
            <key>scope</key>
            <string>programming.source.crystal, source.crystal</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Zig programming source</string>
            <key>scope</key>
            <string>programming.source.zig, source.zig</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>V programming source</string>
            <key>scope</key>
            <string>programming.source.v, source.v</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Configuration files</string>
            <key>scope</key>
            <string>text.configuration, source.configuration</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Documentation files</string>
            <key>scope</key>
            <string>text.documentation, source.documentation</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Data files</string>
            <key>scope</key>
            <string>text.data, source.data</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Raku programming source</string>
            <key>scope</key>
            <string>programming.source.raku, source.raku, programming.source.perl6, source.perl6</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Perl programming source</string>
            <key>scope</key>
            <string>programming.source.perl, source.perl</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Ruby programming source</string>
            <key>scope</key>
            <string>programming.source.ruby, source.ruby</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Python programming source</string>
            <key>scope</key>
            <string>programming.source.python, source.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>JavaScript programming source</string>
            <key>scope</key>
            <string>programming.source.js, source.js, programming.source.javascript, source.javascript</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>TypeScript programming source</string>
            <key>scope</key>
            <string>programming.source.ts, source.ts, programming.source.typescript, source.typescript</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Java programming source</string>
            <key>scope</key>
            <string>programming.source.java, source.java</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>C programming source</string>
            <key>scope</key>
            <string>programming.source.c, source.c</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>C++ programming source</string>
            <key>scope</key>
            <string>programming.source.cpp, source.cpp, programming.source.c++, source.c++</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>C# programming source</string>
            <key>scope</key>
            <string>programming.source.csharp, source.csharp, programming.source.cs, source.cs</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Go programming source</string>
            <key>scope</key>
            <string>programming.source.go, source.go</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Rust programming source</string>
            <key>scope</key>
            <string>programming.source.rust, source.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Swift programming source</string>
            <key>scope</key>
            <string>programming.source.swift, source.swift</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>PHP programming source</string>
            <key>scope</key>
            <string>programming.source.php, source.php</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>HTML programming source</string>
            <key>scope</key>
            <string>programming.source.html, source.html, text.html</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>CSS programming source</string>
            <key>scope</key>
            <string>programming.source.css, source.css, text.css</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>SQL programming source</string>
            <key>scope</key>
            <string>programming.source.sql, source.sql</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>YAML programming source</string>
            <key>scope</key>
            <string>programming.source.yaml, source.yaml, text.yaml</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>JSON programming source</string>
            <key>scope</key>
            <string>programming.source.json, source.json, text.json</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>XML programming source</string>
            <key>scope</key>
            <string>programming.source.xml, source.xml, text.xml</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>TOML programming source</string>
            <key>scope</key>
            <string>programming.source.toml, source.toml, text.toml</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>INI programming source</string>
            <key>scope</key>
            <string>programming.source.ini, source.ini, text.ini</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markdown text source</string>
            <key>scope</key>
            <string>text.markdown, source.markdown, text.md, source.md</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Dockerfile source</string>
            <key>scope</key>
            <string>programming.source.dockerfile, source.dockerfile</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Makefile source</string>
            <key>scope</key>
            <string>programming.source.makefile, source.makefile</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>CMake source</string>
            <key>scope</key>
            <string>programming.source.cmake, source.cmake</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Nix source</string>
            <key>scope</key>
            <string>programming.source.nix, source.nix</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>TeX/LaTeX source</string>
            <key>scope</key>
            <string>programming.source.tex, source.tex, text.tex, programming.source.latex, source.latex, text.latex</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Vim script source</string>
            <key>scope</key>
            <string>programming.source.vim, source.vim, programming.source.viml, source.viml</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Emacs Lisp source</string>
            <key>scope</key>
            <string>programming.source.emacs-lisp, source.emacs-lisp, programming.source.elisp, source.elisp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Generic text files</string>
            <key>scope</key>
            <string>text.plain, source.text, text.txt</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Generic programming source</string>
            <key>scope</key>
            <string>programming.source, source</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling</string>
            <key>scope</key>
            <string>programming.tooling</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style</string>
            <key>scope</key>
            <string>programming.tooling.code-style</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style Python</string>
            <key>scope</key>
            <string>programming.tooling.code-style.python</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style JavaScript</string>
            <key>scope</key>
            <string>programming.tooling.code-style.javascript, programming.tooling.code-style.js</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style TypeScript</string>
            <key>scope</key>
            <string>programming.tooling.code-style.typescript, programming.tooling.code-style.ts</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style Java</string>
            <key>scope</key>
            <string>programming.tooling.code-style.java</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style C</string>
            <key>scope</key>
            <string>programming.tooling.code-style.c, programming.tooling.code-style.cpp, programming.tooling.code-style.c++</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style C#</string>
            <key>scope</key>
            <string>programming.tooling.code-style.csharp, programming.tooling.code-style.cs</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style Go</string>
            <key>scope</key>
            <string>programming.tooling.code-style.go</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style Rust</string>
            <key>scope</key>
            <string>programming.tooling.code-style.rust</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style Ruby</string>
            <key>scope</key>
            <string>programming.tooling.code-style.ruby</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style PHP</string>
            <key>scope</key>
            <string>programming.tooling.code-style.php</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style Swift</string>
            <key>scope</key>
            <string>programming.tooling.code-style.swift</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style Kotlin</string>
            <key>scope</key>
            <string>programming.tooling.code-style.kotlin</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style Scala</string>
            <key>scope</key>
            <string>programming.tooling.code-style.scala</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling code-style Dart</string>
            <key>scope</key>
            <string>programming.tooling.code-style.dart</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling build</string>
            <key>scope</key>
            <string>programming.tooling.build</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling test</string>
            <key>scope</key>
            <string>programming.tooling.test</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling debug</string>
            <key>scope</key>
            <string>programming.tooling.debug</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling package</string>
            <key>scope</key>
            <string>programming.tooling.package</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling linter</string>
            <key>scope</key>
            <string>programming.tooling.linter</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming tooling formatter</string>
            <key>scope</key>
            <string>programming.tooling.formatter</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming config</string>
            <key>scope</key>
            <string>programming.config</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming language all wildcards</string>
            <key>scope</key>
            <string>programming.language, programming.language.python, programming.language.javascript, programming.language.java, programming.language.c, programming.language.cpp, programming.language.go, programming.language.rust, programming.language.ruby, programming.language.php, programming.language.swift, programming.language.kotlin, programming.language.scala, programming.language.dart, programming.language.typescript, programming.language.csharp</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Text wildcards</string>
            <key>scope</key>
            <string>text, text.log, text.output, text.console</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Text configuration Qt</string>
            <key>scope</key>
            <string>text.configuration.qt</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Perl programming source redundant fix</string>
            <key>scope</key>
            <string>programming.source.perl</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Source perl fallback</string>
            <key>scope</key>
            <string>source.perl</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>All perl variants</string>
            <key>scope</key>
            <string>perl, source.pl, programming.pl, text.perl, programming.source.pl</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Text configuration all subcategories</string>
            <key>scope</key>
            <string>text.configuration.xml, text.configuration.json, text.configuration.yaml, text.configuration.toml, text.configuration.ini, text.configuration.properties, text.configuration.conf, text.configuration.config, text.configuration.cfg, text.configuration.settings, text.configuration.plist, text.configuration.desktop, text.configuration.service, text.configuration.unit, text.configuration.env, text.configuration.environment, text.configuration.dotenv, text.configuration.rc, text.configuration.profile, text.configuration.bashrc, text.configuration.zshrc, text.configuration.vimrc, text.configuration.gitconfig, text.configuration.gitignore, text.configuration.editorconfig, text.configuration.eslintrc, text.configuration.prettierrc, text.configuration.tsconfig, text.configuration.jsconfig, text.configuration.package-json, text.configuration.cargo-toml, text.configuration.pyproject-toml, text.configuration.setup-py, text.configuration.requirements-txt, text.configuration.dockerfile, text.configuration.docker-compose, text.configuration.kubernetes, text.configuration.helm, text.configuration.terraform, text.configuration.ansible, text.configuration.vagrant, text.configuration.nginx, text.configuration.apache, text.configuration.systemd, text.configuration.cron, text.configuration.logrotate, text.configuration.ssh, text.configuration.hosts, text.configuration.resolv, text.configuration.fstab, text.configuration.passwd, text.configuration.group, text.configuration.sudoers, text.configuration.xinetd, text.configuration.network, text.configuration.interfaces, text.configuration.dhcp, text.configuration.dns, text.configuration.bind, text.configuration.postfix, text.configuration.sendmail, text.configuration.procmail, text.configuration.crontab, text.configuration.at, text.configuration.batch, text.configuration.shell, text.configuration.script, text.configuration.makefile, text.configuration.cmake, text.configuration.autotools, text.configuration.pkg-config, text.configuration.spec, text.configuration.ebuild, text.configuration.portage, text.configuration.emerge, text.configuration.yum, text.configuration.rpm, text.configuration.deb, text.configuration.dpkg, text.configuration.apt, text.configuration.pacman, text.configuration.emerge, text.configuration.brew, text.configuration.npm, text.configuration.yarn, text.configuration.pip, text.configuration.conda, text.configuration.gem, text.configuration.bundle, text.configuration.composer, text.configuration.maven, text.configuration.gradle, text.configuration.sbt, text.configuration.lein, text.configuration.boot, text.configuration.cargo, text.configuration.mix, text.configuration.rebar, text.configuration.stack, text.configuration.cabal, text.configuration.opam, text.configuration.dune, text.configuration.nix, text.configuration.nixos, text.configuration.home-manager, text.configuration.flake, text.configuration.derivation</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Text all subcategories</string>
            <key>scope</key>
            <string>text.log, text.output, text.console, text.terminal, text.shell, text.command, text.script, text.batch, text.powershell, text.cmd, text.ps1, text.sql, text.query, text.database, text.db, text.csv, text.tsv, text.data, text.dataset, text.table, text.spreadsheet, text.excel, text.ods, text.numbers, text.calc, text.sheet, text.grid, text.matrix, text.vector, text.array, text.list, text.set, text.map, text.hash, text.dictionary, text.object, text.struct, text.record, text.tuple, text.pair, text.key-value, text.property, text.attribute, text.field, text.column, text.row, text.cell, text.value, text.string, text.number, text.integer, text.float, text.double, text.decimal, text.boolean, text.null, text.undefined, text.void, text.empty, text.blank, text.whitespace, text.space, text.tab, text.newline, text.linebreak, text.carriage-return, text.form-feed, text.vertical-tab, text.backspace, text.bell, text.escape, text.control, text.ascii, text.unicode, text.utf8, text.utf16, text.utf32, text.encoding, text.charset, text.locale, text.language, text.region, text.country, text.timezone, text.date, text.time, text.datetime, text.timestamp, text.duration, text.interval, text.period, text.range, text.span, text.window, text.frame, text.buffer, text.stream, text.pipe, text.queue, text.stack, text.heap, text.memory, text.storage, text.cache, text.temp, text.temporary, text.backup, text.archive, text.zip, text.tar, text.gzip, text.compress, text.binary, text.executable, text.library, text.shared, text.static, text.dynamic, text.link, text.symlink, text.shortcut, text.alias, text.reference, text.pointer, text.address, text.path, text.filename, text.extension, text.suffix, text.prefix, text.basename, text.dirname, text.folder, text.directory, text.file, text.document, text.page, text.chapter, text.section, text.paragraph, text.line, text.word, text.character, text.byte, text.bit</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Programming all subcategories</string>
            <key>scope</key>
            <string>programming.syntax, programming.semantic, programming.lexical, programming.grammar, programming.parser, programming.compiler, programming.interpreter, programming.runtime, programming.virtual-machine, programming.bytecode, programming.assembly, programming.machine-code, programming.object-code, programming.executable, programming.library, programming.framework, programming.api, programming.sdk, programming.toolkit, programming.package, programming.module, programming.component, programming.service, programming.daemon, programming.process, programming.thread, programming.coroutine, programming.fiber, programming.task, programming.job, programming.worker, programming.queue, programming.pool, programming.cluster, programming.grid, programming.cloud, programming.container, programming.virtualization, programming.emulation, programming.simulation, programming.modeling, programming.analysis, programming.profiling, programming.debugging, programming.testing, programming.validation, programming.verification, programming.optimization, programming.refactoring, programming.documentation, programming.comment, programming.annotation, programming.metadata, programming.attribute, programming.decorator, programming.pragma, programming.directive, programming.macro, programming.template, programming.generic, programming.polymorphic, programming.inheritance, programming.composition, programming.aggregation, programming.association, programming.dependency, programming.injection, programming.inversion, programming.pattern, programming.principle, programming.paradigm, programming.methodology, programming.practice, programming.convention, programming.standard, programming.specification, programming.protocol, programming.interface, programming.contract, programming.schema, programming.model, programming.view, programming.controller, programming.presenter, programming.viewmodel, programming.entity, programming.value-object, programming.aggregate, programming.repository, programming.service, programming.factory, programming.builder, programming.observer, programming.strategy, programming.command, programming.state, programming.visitor, programming.iterator, programming.proxy, programming.adapter, programming.facade, programming.bridge, programming.composite, programming.decorator, programming.flyweight, programming.singleton, programming.prototype, programming.chain-of-responsibility, programming.mediator, programming.memento, programming.template-method, programming.abstract-factory, programming.factory-method</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Markup all subcategories</string>
            <key>scope</key>
            <string>markup.heading, markup.subheading, markup.title, markup.subtitle, markup.paragraph, markup.list, markup.item, markup.ordered, markup.unordered, markup.definition, markup.table, markup.row, markup.cell, markup.header, markup.footer, markup.sidebar, markup.navigation, markup.menu, markup.toolbar, markup.statusbar, markup.tooltip, markup.popup, markup.modal, markup.dialog, markup.window, markup.frame, markup.panel, markup.tab, markup.accordion, markup.carousel, markup.slider, markup.progress, markup.meter, markup.gauge, markup.chart, markup.graph, markup.diagram, markup.flowchart, markup.timeline, markup.calendar, markup.schedule, markup.agenda, markup.task, markup.todo, markup.note, markup.annotation, markup.comment, markup.remark, markup.aside, markup.blockquote, markup.citation, markup.reference, markup.footnote, markup.endnote, markup.glossary, markup.index, markup.appendix, markup.bibliography, markup.acknowledgment, markup.preface, markup.introduction, markup.conclusion, markup.summary, markup.abstract, markup.overview, markup.outline, markup.toc, markup.contents, markup.chapter, markup.section, markup.subsection, markup.subsubsection, markup.part, markup.book, markup.article, markup.paper, markup.report, markup.thesis, markup.dissertation, markup.manual, markup.guide, markup.tutorial, markup.howto, markup.faq, markup.readme, markup.changelog, markup.license, markup.copyright, markup.trademark, markup.patent, markup.legal, markup.disclaimer, markup.warning, markup.notice, markup.alert, markup.error, markup.info, markup.success, markup.debug, markup.trace, markup.log, markup.audit, markup.security, markup.privacy, markup.terms, markup.policy, markup.agreement, markup.contract, markup.specification, markup.documentation, markup.help, markup.support, markup.contact, markup.about, markup.profile, markup.bio, markup.resume, markup.cv, markup.portfolio, markup.gallery, markup.album, markup.collection, markup.archive, markup.history, markup.timeline, markup.news, markup.blog, markup.post, markup.entry, markup.message, markup.email, markup.letter, markup.memo, markup.draft, markup.template, markup.form, markup.survey, markup.quiz, markup.test, markup.exam, markup.assignment, markup.homework, markup.exercise, markup.problem, markup.solution, markup.answer, markup.result, markup.score, markup.grade, markup.mark, markup.rating, markup.review, markup.feedback, markup.comment, markup.discussion, markup.forum, markup.thread, markup.topic, markup.subject, markup.category, markup.tag, markup.label, markup.keyword, markup.term, markup.phrase, markup.word, markup.text, markup.content, markup.body, markup.main, markup.primary, markup.secondary, markup.tertiary, markup.auxiliary, markup.supplementary, markup.additional, markup.extra, markup.bonus, markup.optional, markup.required, markup.mandatory, markup.essential, markup.critical, markup.important, markup.urgent, markup.priority, markup.high, markup.medium, markup.low, markup.normal, markup.default, markup.standard, markup.basic, markup.advanced, markup.expert, markup.professional, markup.commercial, markup.enterprise, markup.business, markup.corporate, markup.organization, markup.institution, markup.government, markup.public, markup.private, markup.personal, markup.individual, markup.user, markup.member, markup.guest, markup.visitor, markup.client, markup.customer, markup.subscriber, markup.follower, markup.friend, markup.contact, markup.relationship, markup.connection, markup.network, markup.community, markup.group, markup.team, markup.organization, markup.company, markup.brand, markup.product, markup.service, markup.feature, markup.function, markup.capability, markup.skill, markup.talent, markup.ability, markup.expertise, markup.knowledge, markup.experience, markup.background, markup.education, markup.training, markup.certification, markup.qualification, markup.credential, markup.achievement, markup.accomplishment, markup.success, markup.failure, markup.mistake, markup.error, markup.bug, markup.issue, markup.problem, markup.challenge, markup.opportunity, markup.possibility, markup.potential, markup.prospect, markup.future, markup.plan, markup.goal, markup.objective, markup.target, markup.aim, markup.purpose, markup.mission, markup.vision, markup.strategy, markup.tactic, markup.approach, markup.method, markup.technique, markup.procedure, markup.process, markup.workflow, markup.pipeline, markup.sequence, markup.step, markup.stage, markup.phase, markup.iteration, markup.cycle, markup.loop, markup.branch, markup.condition, markup.case, markup.scenario, markup.situation, markup.context, markup.environment, markup.setting, markup.configuration, markup.setup, markup.installation, markup.deployment, markup.release, markup.version, markup.update, markup.upgrade, markup.patch, markup.fix, markup.enhancement, markup.improvement, markup.optimization, markup.performance, markup.efficiency, markup.speed, markup.quality, markup.reliability, markup.stability, markup.security, markup.safety, markup.protection, markup.privacy, markup.confidentiality, markup.integrity, markup.authenticity, markup.validity, markup.accuracy, markup.precision, markup.consistency, markup.compatibility, markup.interoperability, markup.portability, markup.scalability, markup.flexibility, markup.extensibility, markup.maintainability, markup.readability, markup.usability, markup.accessibility, markup.availability, markup.durability, markup.sustainability, markup.viability, markup.feasibility, markup.practicality, markup.utility, markup.value, markup.benefit, markup.advantage, markup.strength, markup.weakness, markup.limitation, markup.constraint, markup.requirement, markup.specification, markup.standard, markup.guideline, markup.recommendation, markup.suggestion, markup.advice, markup.tip, markup.hint, markup.clue, markup.indication, markup.signal, markup.sign, markup.symbol, markup.icon, markup.image, markup.picture, markup.photo, markup.graphic, markup.illustration, markup.diagram, markup.chart, markup.graph, markup.map, markup.layout, markup.design, markup.style, markup.theme, markup.appearance, markup.look, markup.feel, markup.aesthetic, markup.beauty, markup.elegance, markup.simplicity, markup.complexity, markup.sophistication, markup.innovation, markup.creativity, markup.originality, markup.uniqueness, markup.distinctiveness, markup.character, markup.personality, markup.identity, markup.brand, markup.reputation, markup.image, markup.perception, markup.impression, markup.opinion, markup.view, markup.perspective, markup.angle, markup.point, markup.aspect, markup.dimension, markup.facet, markup.element, markup.component, markup.part, markup.piece, markup.fragment, markup.segment, markup.portion, markup.section, markup.division, markup.category, markup.class, markup.type, markup.kind, markup.sort, markup.variety, markup.form, markup.shape, markup.structure, markup.organization, markup.arrangement, markup.order, markup.sequence, markup.pattern, markup.format, markup.syntax, markup.grammar, markup.language, markup.dialect, markup.accent, markup.pronunciation, markup.articulation, markup.expression, markup.communication, markup.message, markup.information, markup.data, markup.fact, markup.detail, markup.particular, markup.specific, markup.general, markup.universal, markup.global, markup.local, markup.regional, markup.national, markup.international, markup.worldwide, markup.planetary, markup.cosmic, markup.universal, markup.infinite, markup.eternal, markup.temporary, markup.permanent, markup.stable, markup.variable, markup.constant, markup.fixed, markup.flexible, markup.adaptable, markup.responsive, markup.reactive, markup.proactive, markup.active, markup.passive, markup.static, markup.dynamic, markup.interactive, markup.engaging, markup.compelling, markup.interesting, markup.boring, markup.exciting, markup.thrilling, markup.amazing, markup.wonderful, markup.fantastic, markup.great, markup.good, markup.bad, markup.terrible, markup.awful, markup.horrible, markup.disgusting, markup.beautiful, markup.ugly, markup.pretty, markup.handsome, markup.attractive, markup.unattractive, markup.appealing, markup.repulsive, markup.pleasant, markup.unpleasant, markup.enjoyable, markup.annoying, markup.irritating, markup.frustrating, markup.satisfying, markup.fulfilling, markup.rewarding, markup.disappointing, markup.discouraging, markup.motivating, markup.inspiring, markup.uplifting, markup.depressing, markup.sad, markup.happy, markup.joyful, markup.cheerful, markup.gloomy, markup.dark, markup.bright, markup.light, markup.heavy, markup.soft, markup.hard, markup.smooth, markup.rough, markup.sharp, markup.dull, markup.clear, markup.unclear, markup.obvious, markup.subtle, markup.simple, markup.complex, markup.easy, markup.difficult, markup.challenging, markup.effortless, markup.smooth, markup.rough, markup.bumpy, markup.flat, markup.curved, markup.straight, markup.crooked, markup.bent, markup.twisted, markup.spiral, markup.circular, markup.square, markup.rectangular, markup.triangular, markup.oval, markup.round, markup.pointed, markup.blunt, markup.thin, markup.thick, markup.wide, markup.narrow, markup.long, markup.short, markup.tall, markup.small, markup.large, markup.huge, markup.tiny, markup.massive, markup.gigantic, markup.enormous, markup.immense, markup.vast, markup.expansive, markup.extensive, markup.comprehensive, markup.complete, markup.partial, markup.incomplete, markup.whole, markup.entire, markup.full, markup.empty, markup.vacant, markup.occupied, markup.busy, markup.idle, markup.active, markup.inactive, markup.live, markup.dead, markup.alive, markup.living, markup.breathing, markup.moving, markup.stationary, markup.still, markup.quiet, markup.silent, markup.loud, markup.noisy, markup.sound, markup.music, markup.song, markup.melody, markup.harmony, markup.rhythm, markup.beat, markup.tempo, markup.pace, markup.speed, markup.velocity, markup.acceleration, markup.deceleration, markup.movement, markup.motion, markup.action, markup.activity, markup.operation, markup.function, markup.purpose, markup.role, markup.responsibility, markup.duty, markup.obligation, markup.commitment, markup.promise, markup.guarantee, markup.warranty, markup.assurance, markup.insurance, markup.protection, markup.coverage, markup.support, markup.assistance, markup.help, markup.aid, markup.service, markup.care, markup.attention, markup.focus, markup.concentration, markup.dedication, markup.devotion, markup.loyalty, markup.faithfulness, markup.reliability, markup.dependability, markup.trustworthiness, markup.honesty, markup.integrity, markup.sincerity, markup.authenticity, markup.genuineness, markup.reality, markup.truth, markup.fact, markup.fiction, markup.fantasy, markup.imagination, markup.creativity, markup.innovation, markup.invention, markup.discovery, markup.exploration, markup.investigation, markup.research, markup.study, markup.analysis, markup.examination, markup.inspection, markup.observation, markup.monitoring, markup.surveillance, markup.tracking, markup.following, markup.pursuing, markup.chasing, markup.hunting, markup.searching, markup.seeking, markup.looking, markup.finding, markup.discovering, markup.uncovering, markup.revealing, markup.exposing, markup.showing, markup.displaying, markup.presenting, markup.demonstrating, markup.illustrating, markup.explaining, markup.describing, markup.defining, markup.clarifying, markup.specifying, markup.detailing, markup.elaborating, markup.expanding, markup.extending, markup.enlarging, markup.increasing, markup.growing, markup.developing, markup.evolving, markup.progressing, markup.advancing, markup.improving, markup.enhancing, markup.upgrading, markup.updating, markup.modernizing, markup.renovating, markup.refreshing, markup.reviving, markup.restoring, markup.repairing, markup.fixing, markup.correcting, markup.adjusting, markup.modifying, markup.changing, markup.altering, markup.transforming, markup.converting, markup.translating, markup.interpreting, markup.understanding, markup.comprehending, markup.grasping, markup.knowing, markup.learning, markup.studying, markup.practicing, markup.training, markup.exercising, markup.working, markup.laboring, markup.toiling, markup.struggling, markup.fighting, markup.battling, markup.competing, markup.contesting, markup.challenging, markup.confronting, markup.facing, markup.meeting, markup.encountering, markup.experiencing, markup.feeling, markup.sensing, markup.perceiving, markup.noticing, markup.recognizing, markup.identifying, markup.distinguishing, markup.differentiating, markup.separating, markup.dividing, markup.splitting, markup.breaking, markup.cracking, markup.fracturing, markup.shattering, markup.destroying, markup.demolishing, markup.ruining, markup.damaging, markup.harming, markup.hurting, markup.injuring, markup.wounding, markup.cutting, markup.slicing, markup.chopping, markup.slashing, markup.stabbing, markup.piercing, markup.penetrating, markup.entering, markup.inserting, markup.placing, markup.positioning, markup.locating, markup.situating, markup.establishing, markup.setting, markup.putting, markup.laying, markup.resting, markup.lying, markup.sitting, markup.standing, markup.walking, markup.running, markup.jogging, markup.sprinting, markup.racing, markup.competing, markup.playing, markup.gaming, markup.entertaining, markup.amusing, markup.delighting, markup.pleasing, markup.satisfying, markup.fulfilling, markup.completing, markup.finishing, markup.ending, markup.concluding, markup.terminating, markup.stopping, markup.halting, markup.pausing, markup.waiting, markup.expecting, markup.anticipating, markup.hoping, markup.wishing, markup.wanting, markup.desiring, markup.craving, markup.longing, markup.yearning, markup.missing, markup.lacking, markup.needing, markup.requiring, markup.demanding, markup.requesting, markup.asking, markup.questioning, markup.inquiring, markup.wondering, markup.pondering, markup.thinking, markup.considering, markup.contemplating, markup.reflecting, markup.meditating, markup.concentrating, markup.focusing, markup.attending, markup.listening, markup.hearing, markup.watching, markup.seeing, markup.looking, markup.viewing, markup.observing, markup.witnessing, markup.experiencing, markup.living, markup.existing, markup.being, markup.becoming, markup.growing, markup.developing, markup.maturing, markup.aging, markup.changing, markup.evolving, markup.transforming, markup.adapting, markup.adjusting, markup.accommodating, markup.accepting, markup.embracing, markup.welcoming, markup.greeting, markup.meeting, markup.introducing, markup.presenting, markup.showing, markup.revealing, markup.sharing, markup.giving, markup.offering, markup.providing, markup.supplying, markup.delivering, markup.sending, markup.transmitting, markup.communicating, markup.conveying, markup.expressing, markup.articulating, markup.speaking, markup.talking, markup.saying, markup.telling, markup.narrating, markup.recounting, markup.describing, markup.explaining, markup.clarifying, markup.illustrating, markup.demonstrating, markup.showing, markup.proving, markup.confirming, markup.verifying, markup.validating, markup.authenticating, markup.certifying, markup.approving, markup.endorsing, markup.recommending, markup.suggesting, markup.proposing, markup.offering, markup.presenting, markup.submitting, markup.providing, markup.giving, markup.donating, markup.contributing, markup.participating, markup.joining, markup.entering, markup.engaging, markup.involving, markup.including, markup.containing, markup.holding, markup.carrying, markup.bearing, markup.supporting, markup.sustaining, markup.maintaining, markup.preserving, markup.protecting, markup.defending, markup.guarding, markup.watching, markup.monitoring, markup.supervising, markup.overseeing, markup.managing, markup.controlling, markup.directing, markup.leading, markup.guiding, markup.steering, markup.navigating, markup.driving, markup.operating, markup.running, markup.executing, markup.performing, markup.conducting, markup.carrying out, markup.implementing, markup.applying, markup.using, markup.utilizing, markup.employing, markup.deploying, markup.installing, markup.setting up, markup.configuring, markup.customizing, markup.personalizing, markup.tailoring, markup.adapting, markup.modifying, markup.adjusting, markup.tuning, markup.optimizing, markup.improving, markup.enhancing, markup.upgrading, markup.updating, markup.refreshing, markup.renewing, markup.revising, markup.editing, markup.correcting, markup.fixing, markup.repairing, markup.restoring, markup.recovering, markup.retrieving, markup.reclaiming, markup.regaining, markup.returning, markup.coming back, markup.going back, markup.reverting, markup.undoing, markup.canceling, markup.aborting, markup.stopping, markup.ending, markup.finishing, markup.completing, markup.accomplishing, markup.achieving, markup.succeeding, markup.winning, markup.triumphing, markup.conquering, markup.overcoming, markup.defeating, markup.beating, markup.surpassing, markup.exceeding, markup.outperforming, markup.outdoing, markup.outshining, markup.excelling, markup.standing out, markup.distinguishing, markup.highlighting, markup.emphasizing, markup.stressing, markup.accentuating, markup.underlining, markup.marking, markup.noting, markup.commenting, markup.remarking, markup.observing, markup.mentioning, markup.referring, markup.citing, markup.quoting, markup.paraphrasing, markup.summarizing, markup.condensing, markup.compressing, markup.reducing, markup.minimizing, markup.decreasing, markup.lowering, markup.dropping, markup.falling, markup.declining, markup.deteriorating, markup.worsening, markup.degrading, markup.eroding, markup.corroding, markup.rotting, markup.decaying, markup.decomposing, markup.dissolving, markup.melting, markup.evaporating, markup.vaporizing, markup.disappearing, markup.vanishing, markup.fading, markup.dimming, markup.darkening, markup.shadowing, markup.covering, markup.hiding, markup.concealing, markup.masking, markup.disguising, markup.camouflaging, markup.blending, markup.mixing, markup.combining, markup.merging, markup.joining, markup.connecting, markup.linking, markup.bridging, markup.spanning, markup.crossing, markup.traversing, markup.traveling, markup.journeying, markup.moving, markup.proceeding, markup.advancing, markup.progressing, markup.developing, markup.growing, markup.expanding, markup.spreading, markup.extending, markup.reaching, markup.stretching, markup.lengthening, markup.prolonging, markup.continuing, markup.persisting, markup.enduring, markup.lasting, markup.remaining, markup.staying, markup.dwelling, markup.residing, markup.living, markup.inhabiting, markup.occupying, markup.filling, markup.crowding, markup.packing, markup.stuffing, markup.loading, markup.charging, markup.powering, markup.energizing, markup.activating, markup.triggering, markup.initiating, markup.starting, markup.beginning, markup.commencing, markup.launching, markup.opening, markup.creating, markup.making, markup.building, markup.constructing, markup.assembling, markup.manufacturing, markup.producing, markup.generating, markup.forming, markup.shaping, markup.molding, markup.sculpting, markup.carving, markup.cutting, markup.trimming, markup.clipping, markup.pruning, markup.editing, markup.revising, markup.refining, markup.polishing, markup.perfecting, markup.completing, markup.finalizing, markup.concluding, markup.wrapping up, markup.closing, markup.sealing, markup.locking, markup.securing, markup.fastening, markup.attaching, markup.connecting, markup.joining, markup.binding, markup.tying, markup.knotting, markup.linking, markup.chaining, markup.stringing, markup.threading, markup.weaving, markup.knitting, markup.sewing, markup.stitching, markup.mending, markup.patching, markup.repairing, markup.fixing, markup.restoring, markup.renovating, markup.rebuilding, markup.reconstructing, markup.remaking, markup.recreating, markup.reproducing, markup.duplicating, markup.copying, markup.cloning, markup.mimicking, markup.imitating, markup.emulating, markup.simulating, markup.modeling, markup.representing, markup.depicting, markup.portraying, markup.illustrating, markup.drawing, markup.sketching, markup.painting, markup.coloring, markup.shading, markup.highlighting, markup.emphasizing, markup.accentuating, markup.focusing, markup.concentrating, markup.centering, markup.aligning, markup.positioning, markup.placing, markup.arranging, markup.organizing, markup.sorting, markup.ordering, markup.ranking, markup.rating, markup.grading, markup.scoring, markup.evaluating, markup.assessing, markup.judging, markup.critiquing, markup.reviewing, markup.examining, markup.inspecting, markup.checking, markup.testing, markup.trying, markup.attempting, markup.endeavoring, markup.striving, markup.working, markup.laboring, markup.toiling, markup.struggling, markup.fighting, markup.battling, markup.competing, markup.contesting, markup.challenging, markup.confronting, markup.facing, markup.meeting, markup.encountering, markup.experiencing, markup.undergoing, markup.suffering, markup.enduring, markup.bearing, markup.tolerating, markup.accepting, markup.embracing, markup.welcoming, markup.receiving, markup.getting, markup.obtaining, markup.acquiring, markup.gaining, markup.earning, markup.winning, markup.achieving, markup.accomplishing, markup.succeeding, markup.triumphing, markup.prevailing, markup.overcoming, markup.conquering, markup.defeating, markup.beating, markup.surpassing, markup.exceeding, markup.transcending, markup.rising above, markup.climbing, markup.ascending, markup.mounting, markup.scaling, markup.reaching, markup.arriving, markup.coming, markup.approaching, markup.nearing, markup.closing in, markup.advancing, markup.progressing, markup.moving forward, markup.going ahead, markup.proceeding, markup.continuing, markup.carrying on, markup.persisting, markup.persevering, markup.enduring, markup.lasting, markup.surviving, markup.living on, markup.thriving, markup.flourishing, markup.blooming, markup.blossoming, markup.flowering, markup.growing, markup.developing, markup.maturing, markup.ripening, markup.aging, markup.evolving, markup.changing, markup.transforming, markup.metamorphosing, markup.converting, markup.turning, markup.becoming, markup.emerging, markup.appearing, markup.surfacing, markup.rising, markup.coming up, markup.showing up, markup.turning up, markup.popping up, markup.springing up, markup.cropping up, markup.arising, markup.occurring, markup.happening, markup.taking place, markup.transpiring, markup.unfolding, markup.developing, markup.progressing, markup.advancing, markup.moving, markup.flowing, markup.streaming, markup.rushing, markup.gushing, markup.pouring, markup.flooding, markup.overflowing, markup.spilling, markup.leaking, markup.dripping, markup.trickling, markup.seeping, markup.oozing, markup.bleeding, markup.sweating, markup.perspiring, markup.breathing, markup.inhaling, markup.exhaling, markup.sighing, markup.gasping, markup.panting, markup.wheezing, markup.coughing, markup.sneezing, markup.yawning, markup.sleeping, markup.dreaming, markup.waking, markup.awakening, markup.rising, markup.getting up, markup.standing, markup.sitting, markup.lying, markup.resting, markup.relaxing, markup.lounging, markup.reclining, markup.leaning, markup.bending, markup.stooping, markup.crouching, markup.kneeling, markup.crawling, markup.creeping, markup.sneaking, markup.tiptoeing, markup.walking, markup.stepping, markup.striding, markup.marching, markup.hiking, markup.trekking, markup.wandering, markup.roaming, markup.strolling, markup.sauntering, markup.ambling, markup.meandering, markup.drifting, markup.floating, markup.gliding, markup.sliding, markup.slipping, markup.skidding, markup.tumbling, markup.rolling, markup.spinning, markup.turning, markup.rotating, markup.revolving, markup.circling, markup.orbiting, markup.cycling, markup.looping, markup.spiraling, markup.twisting, markup.winding, markup.coiling, markup.wrapping, markup.encircling, markup.surrounding, markup.encompassing, markup.enveloping, markup.covering, markup.blanketing, markup.shrouding, markup.veiling, markup.masking, markup.concealing, markup.hiding, markup.obscuring, markup.blocking, markup.obstructing, markup.hindering, markup.impeding, markup.hampering, markup.restraining, markup.restricting, markup.limiting, markup.confining, markup.constraining, markup.binding, markup.tying, markup.fastening, markup.securing, markup.locking, markup.sealing, markup.closing, markup.shutting, markup.opening, markup.unlocking, markup.releasing, markup.freeing, markup.liberating, markup.emancipating, markup.delivering, markup.rescuing, markup.saving, markup.preserving, markup.protecting, markup.defending, markup.guarding, markup.shielding, markup.sheltering, markup.harboring, markup.housing, markup.accommodating, markup.hosting, markup.entertaining, markup.welcoming, markup.greeting, markup.receiving, markup.accepting, markup.embracing, markup.hugging, markup.kissing, markup.caressing, markup.touching, markup.feeling, markup.sensing, markup.perceiving, markup.detecting, markup.discovering, markup.finding, markup.locating, markup.identifying, markup.recognizing, markup.distinguishing, markup.differentiating, markup.comparing, markup.contrasting, markup.matching, markup.pairing, markup.coupling, markup.linking, markup.connecting, markup.joining, markup.uniting, markup.merging, markup.combining, markup.mixing, markup.blending, markup.fusing, markup.melting, markup.dissolving, markup.integrating, markup.incorporating, markup.including, markup.adding, markup.inserting, markup.placing, markup.putting, markup.setting, markup.positioning, markup.arranging, markup.organizing, markup.structuring, markup.formatting, markup.styling, markup.designing, markup.creating, markup.making, markup.building, markup.constructing, markup.assembling, markup.manufacturing, markup.producing, markup.generating, markup.forming, markup.shaping, markup.molding, markup.sculpting, markup.carving, markup.engraving, markup.etching, markup.printing, markup.publishing, markup.releasing, markup.issuing, markup.distributing, markup.delivering, markup.shipping, markup.sending, markup.transmitting, markup.broadcasting, markup.announcing, markup.declaring, markup.proclaiming, markup.stating, markup.asserting, markup.claiming, markup.maintaining, markup.insisting, markup.arguing, markup.debating, markup.discussing, markup.talking, markup.speaking, markup.saying, markup.telling, markup.narrating, markup.recounting, markup.describing, markup.explaining, markup.clarifying, markup.elucidating, markup.illuminating, markup.enlightening, markup.educating, markup.teaching, markup.instructing, markup.training, markup.coaching, markup.mentoring, markup.guiding, markup.directing, markup.leading, markup.managing, markup.supervising, markup.overseeing, markup.monitoring, markup.watching, markup.observing, markup.studying, markup.examining, markup.inspecting, markup.investigating, markup.researching, markup.exploring, markup.discovering, markup.uncovering, markup.revealing, markup.exposing, markup.showing, markup.displaying, markup.exhibiting, markup.presenting, markup.demonstrating, markup.proving, markup.confirming, markup.verifying, markup.validating, markup.authenticating, markup.certifying, markup.approving, markup.endorsing, markup.supporting, markup.backing, markup.sponsoring, markup.funding, markup.financing, markup.investing, markup.purchasing, markup.buying, markup.acquiring, markup.obtaining, markup.getting, markup.receiving, markup.accepting, markup.taking, markup.grabbing, markup.seizing, markup.capturing, markup.catching, markup.trapping, markup.snaring, markup.netting, markup.fishing, markup.hunting, markup.searching, markup.seeking, markup.looking, markup.finding, markup.discovering, markup.locating, markup.tracking, markup.following, markup.pursuing, markup.chasing, markup.running after, markup.going after, markup.coming after, markup.succeeding, markup.following, markup.replacing, markup.substituting, markup.swapping, markup.exchanging, markup.trading, markup.bartering, markup.negotiating, markup.bargaining, markup.dealing, markup.conducting, markup.managing, markup.handling, markup.processing, markup.treating, markup.addressing, markup.tackling, markup.approaching, markup.confronting, markup.facing, markup.meeting, markup.encountering, markup.experiencing, markup.undergoing, markup.suffering, markup.enduring, markup.bearing, markup.tolerating, markup.accepting, markup.embracing, markup.welcoming, markup.receiving, markup.getting, markup.obtaining, markup.acquiring, markup.gaining, markup.earning, markup.winning, markup.achieving, markup.accomplishing, markup.succeeding, markup.triumphing, markup.prevailing, markup.overcoming, markup.conquering, markup.defeating, markup.beating, markup.surpassing, markup.exceeding, markup.transcending, markup.rising above, markup.climbing, markup.ascending, markup.mounting, markup.scaling, markup.reaching, markup.arriving, markup.coming, markup.approaching, markup.nearing, markup.closing in, markup.advancing, markup.progressing, markup.moving forward, markup.going ahead, markup.proceeding, markup.continuing, markup.carrying on, markup.persisting, markup.persevering, markup.enduring, markup.lasting, markup.surviving, markup.living on, markup.thriving, markup.flourishing, markup.blooming, markup.blossoming, markup.flowering, markup.growing, markup.developing, markup.maturing, markup.ripening, markup.aging, markup.evolving, markup.changing, markup.transforming, markup.metamorphosing, markup.converting, markup.turning, markup.becoming, markup.emerging, markup.appearing, markup.surfacing, markup.rising, markup.coming up, markup.showing up, markup.turning up, markup.popping up, markup.springing up, markup.cropping up, markup.arising, markup.occurring, markup.happening, markup.taking place, markup.transpiring, markup.unfolding, markup.developing, markup.progressing, markup.advancing, markup.moving, markup.flowing, markup.streaming, markup.rushing, markup.gushing, markup.pouring, markup.flooding, markup.overflowing, markup.spilling, markup.leaking, markup.dripping, markup.trickling, markup.seeping, markup.oozing, markup.bleeding, markup.sweating, markup.perspiring, markup.breathing, markup.inhaling, markup.exhaling, markup.sighing, markup.gasping, markup.panting, markup.wheezing, markup.coughing, markup.sneezing, markup.yawning, markup.sleeping, markup.dreaming, markup.waking, markup.awakening, markup.rising, markup.getting up, markup.standing, markup.sitting, markup.lying, markup.resting, markup.relaxing, markup.lounging, markup.reclining, markup.leaning, markup.bending, markup.stooping, markup.crouching, markup.kneeling, markup.crawling, markup.creeping, markup.sneaking, markup.tiptoeing, markup.walking, markup.stepping, markup.striding, markup.marching, markup.hiking, markup.trekking, markup.wandering, markup.roaming, markup.strolling, markup.sauntering, markup.ambling, markup.meandering, markup.drifting, markup.floating, markup.gliding, markup.sliding, markup.slipping, markup.skidding, markup.tumbling, markup.rolling, markup.spinning, markup.turning, markup.rotating, markup.revolving, markup.circling, markup.orbiting, markup.cycling, markup.looping, markup.spiraling, markup.twisting, markup.winding, markup.coiling, markup.wrapping, markup.encircling, markup.surrounding, markup.encompassing, markup.enveloping, markup.covering, markup.blanketing, markup.shrouding, markup.veiling, markup.masking, markup.concealing, markup.hiding, markup.obscuring, markup.blocking, markup.obstructing, markup.hindering, markup.impeding, markup.hampering, markup.restraining, markup.restricting, markup.limiting, markup.confining, markup.constraining, markup.binding, markup.tying, markup.fastening, markup.securing, markup.locking, markup.sealing, markup.closing, markup.shutting, markup.opening, markup.unlocking, markup.releasing, markup.freeing, markup.liberating, markup.emancipating, markup.delivering, markup.rescuing, markup.saving, markup.preserving, markup.protecting, markup.defending, markup.guarding, markup.shielding, markup.sheltering, markup.harboring, markup.housing, markup.accommodating, markup.hosting, markup.entertaining, markup.welcoming, markup.greeting, markup.receiving, markup.accepting, markup.embracing, markup.hugging, markup.kissing, markup.caressing, markup.touching, markup.feeling, markup.sensing, markup.perceiving, markup.detecting, markup.discovering, markup.finding, markup.locating, markup.identifying, markup.recognizing, markup.distinguishing, markup.differentiating, markup.comparing, markup.contrasting, markup.matching, markup.pairing, markup.coupling, markup.linking, markup.connecting, markup.joining, markup.uniting, markup.merging, markup.combining, markup.mixing, markup.blending, markup.fusing, markup.melting, markup.dissolving, markup.integrating, markup.incorporating, markup.including, markup.adding, markup.inserting, markup.placing, markup.putting, markup.setting, markup.positioning, markup.arranging, markup.organizing, markup.structuring, markup.formatting, markup.styling, markup.designing, markup.creating, markup.making, markup.building, markup.constructing, markup.assembling, markup.manufacturing, markup.producing, markup.generating, markup.forming, markup.shaping, markup.molding, markup.sculpting, markup.carving, markup.engraving, markup.etching, markup.printing, markup.publishing, markup.releasing, markup.issuing, markup.distributing, markup.delivering, markup.shipping, markup.sending, markup.transmitting, markup.broadcasting, markup.announcing, markup.declaring, markup.proclaiming, markup.stating, markup.asserting, markup.claiming, markup.maintaining, markup.insisting, markup.arguing, markup.debating, markup.discussing, markup.talking, markup.speaking, markup.saying, markup.telling, markup.narrating, markup.recounting, markup.describing, markup.explaining, markup.clarifying, markup.elucidating, markup.illuminating, markup.enlightening, markup.educating, markup.teaching, markup.instructing, markup.training, markup.coaching, markup.mentoring, markup.guiding, markup.directing, markup.leading, markup.managing, markup.supervising, markup.overseeing, markup.monitoring, markup.watching, markup.observing, markup.studying, markup.examining, markup.inspecting, markup.investigating, markup.researching, markup.exploring, markup.discovering, markup.uncovering, markup.revealing, markup.exposing, markup.showing, markup.displaying, markup.exhibiting, markup.presenting, markup.demonstrating, markup.proving, markup.confirming, markup.verifying, markup.validating, markup.authenticating, markup.certifying, markup.approving, markup.endorsing, markup.supporting, markup.backing, markup.sponsoring, markup.funding, markup.financing, markup.investing, markup.purchasing, markup.buying, markup.acquiring, markup.obtaining, markup.getting, markup.receiving, markup.accepting, markup.taking, markup.grabbing, markup.seizing, markup.capturing, markup.catching, markup.trapping, markup.snaring, markup.netting, markup.fishing, markup.hunting, markup.searching, markup.seeking, markup.looking, markup.finding, markup.discovering, markup.locating, markup.tracking, markup.following, markup.pursuing, markup.chasing, markup.running after, markup.going after, markup.coming after, markup.succeeding, markup.following, markup.replacing, markup.substituting, markup.swapping, markup.exchanging, markup.trading, markup.bartering, markup.negotiating, markup.bargaining, markup.dealing, markup.conducting, markup.managing, markup.handling, markup.processing, markup.treating, markup.addressing, markup.tackling, markup.approaching, markup.confronting, markup.facing, markup.meeting, markup.encountering, markup.experiencing, markup.undergoing, markup.suffering, markup.enduring, markup.bearing, markup.tolerating, markup.accepting, markup.embracing, markup.welcoming, markup.receiving, markup.getting, markup.obtaining, markup.acquiring, markup.gaining, markup.earning, markup.winning, markup.achieving, markup.accomplishing, markup.succeeding, markup.triumphing, markup.prevailing, markup.overcoming, markup.conquering, markup.defeating, markup.beating, markup.surpassing, markup.exceeding, markup.transcending</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Universal fallback</string>
            <key>scope</key>
            <string>*</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base05}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>markup.heading.synopsis.man, markup.heading.title.man, markup.heading.other.man, markup.heading.env.man</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0E}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>markup.heading.commands.man</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0D}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>markup.heading.env.man</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base17}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>markup.heading.1.markdown</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base08}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>markup.heading.2.markdown</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base09}</string>
            </dict>
          </dict>
          <dict>
            <key>scope</key>
            <string>markup.heading.markdown</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#${base0A}</string>
            </dict>
          </dict>
        </array>
      </dict>
    </plist>
    
  '';
  executable = false;
  };
}