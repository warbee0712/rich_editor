import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:rich_editor/src/extensions/extensions.dart';
import 'package:rich_editor/src/models/callbacks/did_html_change_listener.dart';
import 'package:rich_editor/src/models/callbacks/html_changed_listener.dart';
import 'package:rich_editor/src/models/callbacks/loaded_listener.dart';
import 'package:rich_editor/src/models/editor_state.dart';
import 'package:rich_editor/src/models/enum/command_name.dart';

import '../models/command_state.dart';

/// A class that handles all editor-related javascript functions
class JavascriptExecutorBase {
  InAppWebViewController? _controller;

  String defaultHtml = "<p>\u200B</p>";

  String editorStateChangedCallbackScheme = "editor-state-changed-callback://";

  String defaultEncoding = "UTF-8";

  String? htmlField = "";

  var didHtmlChange = false;

  Map<CommandName, CommandState> commandStates = {};

  List<Map<CommandName, CommandState>> commandStatesChangedListeners =
      <Map<CommandName, CommandState>>[];

  List<DidHtmlChangeListener> didHtmlChangeListeners =
      <DidHtmlChangeListener>[];

  List<HtmlChangedListener> htmlChangedListeners = <HtmlChangedListener>[];

  // protected val fireHtmlChangedListenersQueue = AsyncProducerConsumerQueue<String>(1) { html ->
  // fireHtmlChangedListeners(html)
  // }

  bool isLoaded = false;

  List<LoadedListener> loadedListeners = <LoadedListener>[];

  init(InAppWebViewController? controller) {
    _controller = controller;
  }

  executeJavascript(String command) async {
    return await _controller!.evaluateJavascript(source: 'editor.$command');
  }

  String getCachedHtml() {
    return htmlField!;
  }

  setHtml(String html) async {
    String? baseUrl;
    await executeJavascript("setHtml('" + encodeHtml(html) + "', '$baseUrl');");
    htmlField = html;
  }

  getCurrentHtml() async {
    String? html = await executeJavascript('getEncodedHtml()');
    String? decodedHtml = decodeHtml(html!);
    if (decodedHtml!.startsWith('"') && decodedHtml.endsWith('"')) {
      decodedHtml = decodedHtml.substring(1, decodedHtml.length - 1);
    }
    return decodedHtml;
  }

  bool isDefaultRichTextEditorHtml(String html) {
    return defaultHtml == html;
  }

  // Text commands
  undo() async {
    await executeJavascript("undo();");
  }

  redo() async {
    await executeJavascript("redo();");
  }

  setBold() async {
    await executeJavascript("setBold();");
  }

  setItalic() async {
    await executeJavascript("setItalic();");
  }

  setUnderline() async {
    await executeJavascript("setUnderline();");
  }

  setSubscript() async {
    await executeJavascript("setSubscript();");
  }

  setSuperscript() async {
    await executeJavascript("setSuperscript();");
  }

  setStrikeThrough() async {
    await executeJavascript("setStrikeThrough();");
  }

  setTextColor(Color? color) async {
    String? hex = color!.toHexColorString();
    await executeJavascript("setTextColor('$hex');");
  }

  setTextBackgroundColor(Color? color) async {
    String? hex = color!.toHexColorString();
    await executeJavascript("setTextBackgroundColor('$hex');");
  }

  setFontName(String fontName) async {
    await executeJavascript("setFontName('$fontName');");
  }

  setFontSize(int fontSize) async {
    if (fontSize < 1 || fontSize > 7) {
      throw ("Font size should have a value between 1-7");
    }
    await executeJavascript("setFontSize('$fontSize');");
  }

  setHeading(int heading) async {
    await executeJavascript("setHeading('$heading');");
  }

  setFormattingToParagraph() async {
    await executeJavascript("setFormattingToParagraph();");
  }

  setPreformat() async {
    await executeJavascript("setPreformat();");
  }

  setBlockQuote() async {
    await executeJavascript("setBlockQuote();");
  }

  removeFormat() async {
    await executeJavascript("removeFormat();");
  }

  setJustifyLeft() async {
    await executeJavascript("setJustifyLeft();");
  }

  setJustifyCenter() async {
    await executeJavascript("setJustifyCenter();");
  }

  setJustifyRight() async {
    await executeJavascript("setJustifyRight();");
  }

  setJustifyFull() async {
    await executeJavascript("setJustifyFull();");
  }

  setIndent() async {
    await executeJavascript("setIndent();");
  }

  setOutdent() async {
    await executeJavascript("setOutdent();");
  }

  insertBulletList() async {
    await executeJavascript("insertBulletList();");
  }

  insertNumberedList() async {
    await executeJavascript("insertNumberedList();");
  }

  // Insert element
  insertLink(String url, String title) async {
    await executeJavascript("insertLink('$url', '$title');");
  }

  /// The rotation parameter is used to signal that the image is rotated and should be rotated by CSS by given value.
  /// Rotation can be one of the following values: 0, 90, 180, 270.
  insertImage(String url,
      {String? alt, int? width, int? height, int? rotation}) async {
    if (rotation == null) rotation = 0;
    if (width == null) width = 300;
    if (height == null) height = 300;
    if (alt == null) alt = '';
    await executeJavascript(
      "insertImage('$url', '$alt', '$width', '$height', $rotation);",
    );
  }

  insertVideo(String url,
      {int? width, int? height, bool fromDevice = true}) async {
    bool? local;
    local = fromDevice ? true : null;
    if (width == null) width = 300;
    if (height == null) height = 220;
    // check if link is yt link
    if (url.contains('youtu')) {
      // Get Video id from link.
      String youtubeId = url.split(r'?v=')[1];
      url = 'https://www.youtube.com/embed/$youtubeId';
    }
    await executeJavascript(
      "insertVideo('$url', '$width', '$height', $local);",
    );
  }

  insertCheckbox(String text) async {
    await executeJavascript("insertCheckbox('$text');");
  }

  insertHtml(String html) async {
    String? encodedHtml = encodeHtml(html);
    await executeJavascript("insertHtml('$encodedHtml');");
  }

  makeImagesResizeable() async {
    await executeJavascript("makeImagesResizeable();");
  }

  disableImageResizing() async {
    await executeJavascript("disableImageResizing();");
  }

  // Editor settings commands
  focus() async {
    await executeJavascript("focus();");
  }

  unFocus() async {
    await executeJavascript("blurFocus();");
  }

  setBackgroundColor(Color? color) async {
    String? hex = color!.toHexColorString();
    await executeJavascript("setBackgroundColor('$hex');");
  }

  setBackgroundImage(String image) async {
    await executeJavascript("setBackgroundImage('$image');");
  }

  setBaseTextColor(Color? color) async {
    String? hex = color!.toHexColorString();
    await executeJavascript("setBaseTextColor('$hex');");
  }

  setBaseFontFamily(String fontFamily) async {
    await executeJavascript("setBaseFontFamily('$fontFamily');");
  }

  setPadding(EdgeInsets? padding) async {
    String left = padding!.left.toString();
    String top = padding.top.toString();
    String right = padding.right.toString();
    String bottom = padding.bottom.toString();
    await executeJavascript(
        "setPadding('${left}px', '${top}px', '${right}px', '${bottom}px');");
  }

  // Doesnt actually work for' now
  setPlaceholder(String placeholder) async {
    await executeJavascript("setPlaceholder('$placeholder');");
  }

  setEditorWidth(int px) async {
    await executeJavascript("setWidth('" + px.toString() + "px');");
  }

  setEditorHeight(int px) async {
    await executeJavascript("setHeight('" + px.toString() + "px');");
  }

  setInputEnabled(bool inputEnabled) async {
    await executeJavascript("setInputEnabled($inputEnabled);");
  }

  decodeHtml(String html) {
    return Uri.decodeFull(html);
  }

  encodeHtml(String html) {
    return Uri.encodeFull(html);
  }

  bool shouldOverrideUrlLoading(String url) {
    String decodedUrl;
    try {
      decodedUrl = decodeHtml(url);
    } catch (e) {
      // No handling
      return false;
    }

    if (url.indexOf(editorStateChangedCallbackScheme) == 0) {
      editorStateChanged(
          decodedUrl.substring(editorStateChangedCallbackScheme.length));
      return true;
    }

    return false;
  }

  editorStateChanged(String statesString) {
    try {
      var editorState = EditorState.fromJson(jsonDecode(statesString));

      bool currentHtmlChanged = this.htmlField != editorState.html;
      this.htmlField = editorState.html;

      retrievedEditorState(
          editorState.didHtmlChange!, editorState.commandStates!);

      if (currentHtmlChanged) {
        // fireHtmlChangedListenersAsync(editorState.html);
      }
    } catch (e) {
      throw ("Could not parse command states: $statesString $e");
    }
  }

  retrievedEditorState(
      bool didHtmlChange, Map<CommandName, CommandState> commandStates) {
    if (this.didHtmlChange != didHtmlChange) {
      this.didHtmlChange = didHtmlChange;
      didHtmlChangeListeners.forEach((element) {
        element.didHtmlChange(didHtmlChange);
      });
    }

    handleRetrievedCommandStates(commandStates);
  }

  handleRetrievedCommandStates(Map<CommandName, CommandState> commandStates) {
    determineDerivedCommandStates(commandStates);

    this.commandStates = commandStates;
    commandStatesChangedListeners.forEach((element) {
      element = this.commandStates;
    });
  }

  determineDerivedCommandStates(Map<CommandName, CommandState> commandStates) {
    if (commandStates[CommandName.FORMATBLOCK] != null) {
      var formatCommandState = commandStates[CommandName.FORMATBLOCK];
      commandStates.update(
        CommandName.H1,
        (val) => CommandState(formatCommandState!.executable,
            isFormatActivated(formatCommandState, "h1")),
      );
      commandStates.update(
          CommandName.H2,
          (val) => CommandState(formatCommandState!.executable,
              isFormatActivated(formatCommandState, "h2")));
      commandStates.update(
        CommandName.H3,
        (val) => CommandState(formatCommandState!.executable,
            isFormatActivated(formatCommandState, "h3")),
      );
      commandStates.update(
        CommandName.H4,
        (val) => CommandState(formatCommandState!.executable,
            isFormatActivated(formatCommandState, "h4")),
      );
      commandStates.update(
        CommandName.H5,
        (val) => CommandState(formatCommandState!.executable,
            isFormatActivated(formatCommandState, "h5")),
      );
      commandStates.update(
        CommandName.H6,
        (val) => CommandState(formatCommandState!.executable,
            isFormatActivated(formatCommandState, "h6")),
      );
      commandStates.update(
        CommandName.P,
        (val) => CommandState(formatCommandState!.executable,
            isFormatActivated(formatCommandState, "p")),
      );
      commandStates.update(
        CommandName.PRE,
        (val) => CommandState(formatCommandState!.executable,
            isFormatActivated(formatCommandState, "pre")),
      );
      commandStates.update(
        CommandName.BR,
        (val) => CommandState(formatCommandState!.executable,
            isFormatActivated(formatCommandState, "")),
      );
      commandStates.update(
        CommandName.BLOCKQUOTE,
        (val) => CommandState(formatCommandState!.executable,
            isFormatActivated(formatCommandState, "blockquote")),
      );
    }

    if (commandStates[CommandName.INSERTHTML] != null) {
      CommandState? insertHtmlState = commandStates[CommandName.INSERTHTML];
      commandStates.update(CommandName.INSERTLINK, (val) => insertHtmlState!);
      commandStates.update(CommandName.INSERTIMAGE, (val) => insertHtmlState!);
      commandStates.update(
          CommandName.INSERTCHECKBOX, (val) => insertHtmlState!);
    }
  }

  String isFormatActivated(CommandState formatCommandState, String format) {
    return (formatCommandState.value == format)
        .toString(); // rich_text_editor.js reports boolean values as string, so we also have to convert it to string
  }

  addCommandStatesChangedListener(
      Map<CommandName, CommandState> commandStates) {
    commandStatesChangedListeners.add(commandStates);

    // listener.invoke(commandStates);
  }

  addDidHtmlChangeListener(DidHtmlChangeListener listener) {
    didHtmlChangeListeners.add(listener);
  }

  addHtmlChangedListener(HtmlChangedListener listener) {
    htmlChangedListeners.add(listener);
  }
}
