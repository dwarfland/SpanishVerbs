namespace Verbs;

type
  [IBObject]
  MainWindowController = public class(NSWindowController, INSTableViewDataSource, INSTableViewDelegate)
  public

    constructor;
    begin
      inherited constructor withWindowNibName("MainWindow");

      dataFileName := Path.Combine(Environment.UserApplicationSupportFolder, "Dwarfland", "Verbs.Spanish.xml");
      Log($"dataFileName {dataFileName}");
      if dataFileName.FileExists then begin
        Load;
      end
      else begin
        var defaultDataFile := NSBundle.mainBundle.URLForResource("DefaultVerbs.Spanish") withExtension("xml") as Url;
        if defaultDataFile:FileExists then
          Load(defaultDataFile.FilePath);
      end;

    end;

    method windowDidLoad; override;
    begin
      inherited windowDidLoad();
      UpdateColumns();
    end;

    method Load(aFilenameOverride: nullable String := nil);
    begin
      verbs := new List<Verb>;
      var xml := XmlDocument.TryFromFile(coalesce(aFilenameOverride, dataFileName));
      for each e in xml.Root.ElementsWithName("Verb") do
        verbs.Add(new Verb fromXml(e));
      Sort();
    end;

    method Save;
    begin
      var XmlStyleVisualStudio := new XmlFormattingOptions();
      XmlStyleVisualStudio.WhitespaceStyle := XmlWhitespaceStyle.PreserveWhitespaceAroundText;
      XmlStyleVisualStudio.EmptyTagSyle := XmlTagStyle.PreferSingleTag;
      XmlStyleVisualStudio.Indentation := "  ";
      XmlStyleVisualStudio.NewLineForElements := true;
      XmlStyleVisualStudio.NewLineForAttributes := false;
      XmlStyleVisualStudio.NewLineSymbol := XmlNewLineSymbol.CRLF;
      XmlStyleVisualStudio.SpaceBeforeSlashInEmptyTags := true;
      XmlStyleVisualStudio.WriteNewLineAtEnd := false;
      XmlStyleVisualStudio.WriteBOM := true;

      var xml := XmlDocument.WithRootElement("Verbs");
      for each v in verbs do
        xml.Root.Add(v.ToXml);
      Folder.Create(dataFileName.ParentDirectory);
      xml.SaveToFile(dataFileName, XmlStyleVisualStudio);
    end;

    method Sort;
    begin
      var temp := verbs.OrderBy(v -> v.Infinitive);
      if length(searchString) > 0 then
        temp := temp.Where(v -> columns.Any(c -> v.conjugationsByName[c]:Contains(searchString)));
      visibleVerbs := temp.ToList;
      tableView:reloadData();
    end;

    [IBOutlet]
    property tableView: NSTableView;
    property verbs: List<Verb>;
    property visibleVerbs: List<Verb>;
    property visibleColumns: List<String>;
    property dataFileName: String;

    //
    // INSTableViewDataSource
    //

    method numberOfRowsInTableView(aTableView: NSTableView): NSInteger;
    begin
      result := visibleVerbs:Count+1;
    end;

    method tableView(aTableView: NSTableView) objectValueForTableColumn(aTableColumn: nullable NSTableColumn) row(aRow: NSInteger): nullable id;
    begin
      if aRow = visibleVerbs:Count then begin
        if aTableColumn.identifier ≠ "Infinitive" then
          exit;
        exit "Add...";
      end;

      var verb := visibleVerbs[aRow];
      result := verb.conjugationsByName[aTableColumn.identifier];

      if aTableColumn.identifier = "Infinitive" then
        if verb.StemChange ≠ VerbStemChange.None then
          result := result+$" ({StemChangeToString(verb.StemChange)})"
    end;

    method tableView(aTableView: NSTableView) setObjectValue(object: nullable id) forTableColumn(aTableColumn: nullable NSTableColumn) row(aRow: NSInteger);
    begin
      var value := (object as String):ToLowerInvariant:Trim;

      if aRow = visibleVerbs:Count then begin
        if aTableColumn.identifier ≠ "Infinitive" then
          exit;

        if (length(value) ≥ 2) and value.EndsWith("r") and not value.Contains(".") and not visibleVerbs.Any(v -> v.Infinitive = value) then begin
          verbs.Add(new Verb withInfinitive(value));
          Sort();
          Save();
          tableView.selectRowIndexes(NSIndexSet.indexSetWithIndex(visibleVerbs:Count)) byExtendingSelection(false);
        end;
        exit;
      end;

      var verb := visibleVerbs[aRow];
      if length(value) = 0 then
        value := nil;
      verb.conjugationsByName[aTableColumn.identifier] := value;
      tableView.reloadData();
      Save();
    end;

    method tableView(aTableView: NSTableView) sortDescriptorsDidChange(oldDescriptors: NSArray<NSSortDescriptor>);
    begin

    end;

    //
    // INSTableViewDelegate
    //

    method tableView(aTableView: NSTableView) heightOfRow(row: NSInteger): CGFloat;
    begin
      result := 16.0;
    end;

    method tableView(aTableView: NSTableView) dataCellForTableColumn(aTableColumn: nullable NSTableColumn) row(aRow: NSInteger): nullable NSCell;
    begin
      if not assigned(aTableColumn) then
        exit nil;

      var cell := aTableColumn.dataCell;
      cell.lineBreakMode := NSLineBreakMode.ByTruncatingTail;
      cell.font := NSFont.systemFontOfSize(11.0);
      cell.textColor := NSColor.textColor;

      if aRow = visibleVerbs:Count then begin
        if tableView.selectedRowIndexes.containsIndex(aRow) then
          cell.textColor := NSColor.selectedControlTextColor
        else
          cell.textColor := NSColor.systemRedColor;
        exit;
      end;

      if aTableColumn.identifier = "Infinitive" then begin
        cell.font := NSFont.boldSystemFontOfSize(11.0);
      end
      else if aTableColumn.identifier:hasPrefix("Translation.") then begin
        cell.textColor := NSColor.systemBlueColor;
      end
      else begin
        cell.editable := true;
        var verb := visibleVerbs[aRow];
        if verb.conjugationsIsStandard[aTableColumn.identifier] then begin
          cell.textColor := NSColor.grayColor;
        end
        else begin
          cell.font := NSFont.boldSystemFontOfSize(11.0);
        end;
      end;

      if tableView.selectedRowIndexes.containsIndex(aRow) then
        cell.textColor := NSColor.selectedControlTextColor;

      var verb := visibleVerbs[aRow];
      var value := verb.conjugationsByName[aTableColumn.identifier];
      if (length(searchString) > 0) and value.Contains(searchString) then
        cell.textColor := NSColor.redColor;
    end;

    method tableView(aTableView: NSTableView) toolTipForCell(cell: NSCell) rect(rect: NSRectPointer) tableColumn(tableColumn: nullable NSTableColumn) row(row: NSInteger) mouseLocation(mouseLocation: NSPoint): NSString;
    begin

    end;

    method tableView(aTableView: NSTableView) shouldEditTableColumn(aTableColumn: nullable NSTableColumn) row(aRow: NSInteger): Boolean;
    begin
      if aRow = visibleVerbs:Count then
        exit aTableColumn.identifier = "Infinitive";

      result := aTableColumn.identifier ≠ "Infinitive";
    end;

    method tableView(aTableView: NSTableView) willDisplayCell(cell: id) forTableColumn(tableColumn: nullable NSTableColumn) row(row: NSInteger);
    begin

    end;

    method tableViewSelectionDidChange(notification: NSNotification);
    begin

    end;

    method tableViewSelectionIsChanging(notification: NSNotification);
    begin

    end;

    method tableView(aTableView: NSTableView) menuForTableColumn(aTableColumn: nullable NSTableColumn) row(aRow: NSInteger): NSMenu;
    begin
      if aRow = visibleVerbs:Count then
        exit;

      if aTableColumn.identifier = "Infinitive" then begin

        var verb := visibleVerbs[aRow];

        result := new NSMenu;

        var lStemChangesMenu := new NSMenu;
        lStemChangesMenu.addItemWithTitle("None") action(selector(setStemChange:)) keyEquivalent("");
        lStemChangesMenu.addItemWithTitle("-> i") action(selector(setStemChange:)) keyEquivalent("");
        lStemChangesMenu.addItemWithTitle("-> ie") action(selector(setStemChange:)) keyEquivalent("");
        lStemChangesMenu.addItemWithTitle("-> ue") action(selector(setStemChange:)) keyEquivalent("");
        for each i in lStemChangesMenu.itemArray do begin
          i.representedObject := verb;
          if (verb.StemChange ≠ VerbStemChange.None) and (i.title.hasSuffix(StemChangeToString(verb.StemChange))) then
            i.state := NSOnState;
        end;
        if verb.StemChange = VerbStemChange.None then
          lStemChangesMenu.itemArray[0].state := NSOnState;


        //var lStemChangesItem := new NSMenuItem withTitle() action("Stem Change") keyEquivalent("");
        var lStemChangesItem := new NSMenuItem withTitle("Stem Change") action(nil) keyEquivalent("");
        lStemChangesItem.submenu := lStemChangesMenu;
        result.addItem(lStemChangesItem);

        result.addItem(NSMenuItem.separatorItem);
        result.addItemWithTitle($"Remove '{verb.Infinitive}'") action(selector(setDeleteVerb:)) keyEquivalent("");
        for each i in result.itemArray do
          i.representedObject := verb;
      end

    end;

    [IBAction]
    method setStemChange(aSender: id); public;
    begin
      case aSender.title of
        "-> i": (aSender.representedObject as Verb).StemChange := VerbStemChange.I;
        "-> ie": (aSender.representedObject as Verb).StemChange := VerbStemChange.IE;
        "-> ue": (aSender.representedObject as Verb).StemChange := VerbStemChange.UE;
        else (aSender.representedObject as Verb).StemChange := VerbStemChange.None;
      end;


      Sort();
      Save();
    end;

    [IBAction]
    method setDeleteVerb(aSender: id); public;
    begin
      verbs.Remove(aSender.representedObject as Verb);
      Sort();
      Save();
    end;


    //
    //
    //

    [IBAction]
    method reload(aSender: id); public;
    begin
      Load();
    end;

    [IBAction]
    method exportAsHtml(aSender: id); public;
    begin
      var s := NSSavePanel.savePanel;
      s.allowedFileTypes := new List<String>("html");
      s.allowsOtherFileTypes := false;
      s.nameFieldStringValue := "Spanish Verbs.html";
      //var lResult := await s.beginSheetModalForWindow(window) completionHandler();
      s.beginSheetModalForWindow(window) completionHandler( (r) -> begin

        if r = NSModalResponseOK then begin

          var sb := new StringBuilder;
          sb.AppendLine('<html>');
          sb.AppendLine('<head>');
          sb.AppendLine('  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />');
          sb.AppendLine('  <style>');
          sb.AppendLine('    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol" }');
          sb.AppendLine('    .irregular { font-weight: bold; }');
          sb.AppendLine('    .infinitive { font-weight: bold; color: green; }');
          sb.AppendLine('    .regular { font-weight: bold; color: gray; }');
          sb.AppendLine('    .translation { color: blue; }');
          sb.AppendLine('  </style>');
          sb.AppendLine('</head>');
          sb.AppendLine('<body>');
          sb.AppendLine('  <table>');

          sb.AppendLine('    <tr>');
          for each c in visibleColumns do
            sb.AppendLine($'      <th class="title">{if c.StartsWith("Indicativo.") then "Indicativo" else if c.StartsWith("Subjuntivo.") then "Subjuntivo" else ""}</td>');
          sb.AppendLine('    </tr>');

          sb.AppendLine('    <tr>');
          for each c in visibleColumns do
            sb.AppendLine($'      <th class="title">{FixHeader(c)}</td>');
          sb.AppendLine('    </tr>');

          for each v in visibleVerbs do begin
            sb.AppendLine('    <tr>');
            for each c in visibleColumns do begin
              var lCssClassName := c.ToLowerInvariant.Replace(".", "-");
              if c = "Infinitive" then
                sb.AppendLine($'      <td class="verb {lCssClassName}">{v.conjugationsByName[c]}</td>')
              else if c.StartsWith("Translation.") then
                sb.AppendLine($'      <td class="verb translation {lCssClassName}">{v.conjugationsByName[c]}</td>')
              else if v.conjugationsIsStandard[c] then
                sb.AppendLine($'      <td class="verb regular {lCssClassName}">{v.conjugationsByName[c]}</td>')
              else
                sb.AppendLine($'      <td class="verb irregular {lCssClassName}">{v.conjugationsByName[c]}</td>');
            end;
            sb.AppendLine('    </tr>');
          end;

          sb.AppendLine('  <table>');
          sb.AppendLine('</body>');
          sb.AppendLine('</html>');

          File.WriteText(s.URL.path, sb.ToString);
          NSWorkspace.sharedWorkspace.openURL(s.URL)

        end;

      end);
    end;

    [IBAction]
    method columnsChanged(aSender: id); public;
    begin
      dispatch_async(dispatch_get_main_queue) begin
        UpdateColumns();
      end;
    end;

    [IBAction]
    method filterChanged(aSender: id); public;
    begin
      Sort();
    end;

    [Notify]
    property searchString: String;

    //
    //
    //

    method UpdateColumns;
    begin
      var newColumns := columns as sequence of String;
      if not AppDelegate.sharedInstance.ShowTranslation then
        newColumns := newColumns.Where(c -> not c.StartsWith("Translation."));
      if not AppDelegate.sharedInstance.ShowParticiples then
        newColumns := newColumns.Where(c -> not c.StartsWith("Participle."));
      if not AppDelegate.sharedInstance.ShowImperatives then
        newColumns := newColumns.Where(c -> not c.StartsWith("Imperative."));

      if not AppDelegate.sharedInstance.ShowIndicativo then
        newColumns := newColumns.Where(c -> not c.StartsWith("Indicativo."));
      if not AppDelegate.sharedInstance.ShowSubjuntivo then
        newColumns := newColumns.Where(c -> not c.StartsWith("Subjuntivo."));

      if not AppDelegate.sharedInstance.ShowPresentTense then
        newColumns := newColumns.Where(c -> not c.Contains(".Present."));
      if not AppDelegate.sharedInstance.ShowPreteriteTense then
        newColumns := newColumns.Where(c -> not c.Contains(".Preterite."));
      if not AppDelegate.sharedInstance.ShowImperfectTense then
        newColumns := newColumns.Where(c -> not c.Contains(".Imperfect."));
      if not AppDelegate.sharedInstance.ShowSimpleFutureTense then
        newColumns := newColumns.Where(c -> not c.Contains(".SimpleFuture."));

      if not AppDelegate.sharedInstance.ShowVosAndVosotros then
        newColumns := newColumns.Where(c -> not c.EndsWith(".Plural.2") and not c.Contains("Vos"));

      visibleColumns := newColumns.ToList;

      for each c in tableView.tableColumns.copy do
        tableView.removeTableColumn(c);

      for each c in visibleColumns do begin
        var column := new NSTableColumn();
        column.identifier := c;
        column.headerCell.title := FixHeader(c);
        column.title := FixHeader(c);
        column.editable := true;
        column.minWidth := 100;
        tableView.addTableColumn(column);
      end;
    end;

    method FixHeader(aConfugation: String): String;
    begin
      result := aConfugation;
      if result.StartsWith("Translation.") then
        exit result.SubstringFromFirstOccurrenceOf(".");

      result := result.Replace("Indicativo.", "").Replace("Subjuntivo.", ""); // for now
      result := result.Replace("Simple", "");
      result := result.Replace("Singular", "Sg").Replace("Plural", "Pl").Replace("Vos", " Vos");
      result := result.Replace("1", "1st").Replace("2", "2nd").Replace("3", "3rd");
      var lSplit := result.Split(".");
      if lSplit.Count = 3 then begin
        result := lSplit[2]+" "+lSplit[1]+" "+lSplit[0];
      end;
      if lSplit.Count = 2 then begin
        result := lSplit[1]+" "+lSplit[0];
      end;
    end;

    const /*verb_*/columns : array of String = [
      "Infinitive",
      "Translation.English",
      "Participle.Present",
      "Imperative.Tu",
      "Imperative.Usted",
      "Imperative.Ustedes",
      "Imperative.Nosotros",
      "Imperative.AffirmativeVosotros",
      "Imperative.NegativeVosotros",
      "Imperative.AffirmativeVos",
      "Imperative.NegativeVos",

      "Indicativo.Present.Singular.1",
      "Indicativo.Present.Singular.2",
      "Indicativo.Present.Singular.3",
      "Indicativo.Present.Plural.1",
      "Indicativo.Present.Plural.2",
      "Indicativo.Present.Plural.3",
      "Indicativo.Preterite.Singular.1",
      "Indicativo.Preterite.Singular.2",
      "Indicativo.Preterite.Singular.3",
      "Indicativo.Preterite.Plural.1",
      "Indicativo.Preterite.Plural.2",
      "Indicativo.Preterite.Plural.3",
      "Indicativo.Imperfect.Singular.1",
      "Indicativo.Imperfect.Singular.2",
      "Indicativo.Imperfect.Singular.3",
      "Indicativo.Imperfect.Plural.1",
      "Indicativo.Imperfect.Plural.2",
      "Indicativo.Imperfect.Plural.3",

      "Indicativo.SimpleFuture.Singular.1",
      "Indicativo.SimpleFuture.Singular.2",
      "Indicativo.SimpleFuture.Singular.3",
      "Indicativo.SimpleFuture.Plural.1",
      "Indicativo.SimpleFuture.Plural.2",
      "Indicativo.SimpleFuture.Plural.3",

      "Subjuntivo.Present.Singular.1",
      "Subjuntivo.Present.Singular.2",
      "Subjuntivo.Present.Singular.3",
      "Subjuntivo.Present.Plural.1",
      "Subjuntivo.Present.Plural.2",
      "Subjuntivo.Present.Plural.3",
      "Subjuntivo.Imperfect.Singular.1",
      "Subjuntivo.Imperfect.Singular.2",
      "Subjuntivo.Imperfect.Singular.3",
      "Subjuntivo.Imperfect.Plural.1",
      "Subjuntivo.Imperfect.Plural.2",
      "Subjuntivo.Imperfect.Plural.3",
      ];
  end;

end.