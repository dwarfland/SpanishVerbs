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
      if dataFileName.FileExists then
        Load;

      //verbs := new List<Verb>(new Verb withInfinitive("ir"),
                              //new Verb withInfinitive("leer"),
                              //new Verb withInfinitive("hablar"),
                              //new Verb withInfinitive("comer"),
                              //new Verb withInfinitive("vivir"),
                              //new Verb withInfinitive("volver", VerbStemChange.UE),
                              //new Verb withInfinitive("querer", VerbStemChange.IE));

    end;

    method windowDidLoad; override;
    begin
      inherited windowDidLoad();

      for each c in tableView.tableColumns.copy do
        tableView.removeTableColumn(c);

      for each c in /*verb_*/columns do begin
        var column := new NSTableColumn();
        column.identifier := c;
        column.headerCell.title := c;
        column.title := c;
        column.editable := true;//c ≠ "Infinitive";
        //column.dataCell := new ProjectSettingsCell();
        tableView.addTableColumn(column);
      end;

    end;

    method Load();
    begin
      verbs := new List<Verb>;
      var xml := XmlDocument.TryFromFile(dataFileName);
      for each e in xml.Root.ElementsWithName("Verb") do
        verbs.Add(new Verb fromXml(e));
      Sort();
    end;

    method Save();
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

    method Sort();
    begin
      verbs := verbs.OrderBy(v -> v.Infinitive).ToList;
    end;

    [IBOutlet]
    property tableView: NSTableView;
    property verbs: List<Verb>;
    property dataFileName: String;

    //
    // INSTableViewDataSource
    //

    method numberOfRowsInTableView(aTableView: NSTableView): NSInteger;
    begin
      result := verbs:Count+1;
    end;

    method tableView(aTableView: NSTableView) objectValueForTableColumn(aTableColumn: nullable NSTableColumn) row(aRow: NSInteger): nullable id;
    begin
      if aRow = verbs:Count then begin
        if aTableColumn.identifier ≠ "Infinitive" then
          exit;
        exit "Add...";
      end;

      var verb := verbs[aRow];
      result := verb.conjugationsByName[aTableColumn.identifier];

      if aTableColumn.identifier = "Infinitive" then
        if verb.StemChange ≠ VerbStemChange.None then
          result := result+$" ({StemChangeToString(verb.StemChange)})"
    end;

    method tableView(aTableView: NSTableView) setObjectValue(object: nullable id) forTableColumn(aTableColumn: nullable NSTableColumn) row(aRow: NSInteger);
    begin
      var value := (object as String):ToLowerInvariant;

      if aRow = verbs:Count then begin
        if aTableColumn.identifier ≠ "Infinitive" then
          exit;

        if (length(value) > 0) and not value.Contains(".") and not verbs.Any(v -> v.Infinitive = value) then begin
          verbs.Add(new Verb withInfinitive(value));
          Sort();
          Save();
          tableView.reloadData();
        end;
        exit;
      end;

      var verb := verbs[aRow];
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

      if aRow = verbs:Count then begin
        if tableView.selectedRowIndexes.containsIndex(aRow) then
          cell.textColor := NSColor.selectedControlTextColor
        else
          cell.textColor := NSColor.systemRedColor;
        exit;
      end;

      if aTableColumn.identifier = "Infinitive" then begin
        cell.font := NSFont.boldSystemFontOfSize(11.0);
      end
      else begin
        cell.editable := true;
        var verb := verbs[aRow];
        if verb.conjugationsIsStandard[aTableColumn.identifier] then begin
          cell.textColor := NSColor.grayColor;
        end
        else begin
          cell.font := NSFont.boldSystemFontOfSize(11.0);
        end;
      end;

      if tableView.selectedRowIndexes.containsIndex(aRow) then
        cell.textColor := NSColor.selectedControlTextColor;
    end;

    method tableView(aTableView: NSTableView) toolTipForCell(cell: NSCell) rect(rect: NSRectPointer) tableColumn(tableColumn: nullable NSTableColumn) row(row: NSInteger) mouseLocation(mouseLocation: NSPoint): NSString;
    begin

    end;

    method tableView(aTableView: NSTableView) shouldEditTableColumn(aTableColumn: nullable NSTableColumn) row(aRow: NSInteger): Boolean;
    begin
      if aRow = verbs:Count then
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

    //

    const /*verb_*/columns : array of String = [
      "Infinitive",
      "Participle.Present",
      "Imperative.Singular",
      "Imperative.Plural",
      "Indicativo.Present.Singular.1",
      "Indicativo.Present.Singular.2",
      "Indicativo.Present.Singular.3",
      "Indicativo.Present.Plural.1",
      "Indicativo.Present.Plural.2",
      "Indicativo.Present.Plural.3",
      "Indicativo.Past.Singular.1",
      "Indicativo.Past.Singular.2",
      "Indicativo.Past.Singular.3",
      "Indicativo.Past.Plural.1",
      "Indicativo.Past.Plural.2",
      "Indicativo.Past.Plural.3",
      ];
  end;

end.