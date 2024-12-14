namespace Verbs;

uses
  AppKit;

type
  [IBObject]
  VerbWindowController = public class(NSWindowController, INSTableViewDataSource, INSTableViewDelegate)
  public

    constructor withVerb(aVerb: Verb);
    begin
      inherited constructor withWindowNibName('VerbWindow');
      verb := aVerb;
    end;

    method windowDidLoad; override;
    begin
      inherited windowDidLoad();
      var frame := tableView.headerView.frame;
      frame.size.height := 2*16.0;
      tableView.headerView.frame := frame;

      window.title := if length(verb.conjugationsByName["Translation.English"]) > 0 then
        $"{verb.conjugationsByName["Infinitive"]} ({verb.conjugationsByName["Translation.English"]})"
      else
        verb.conjugationsByName["Infinitive"];
      // Implement this method to handle any initialization after your window controller's
      // window has been loaded from its nib file.
      BroadcastManager.subscribe(self) toBroadcast(AppDelegate.NOTIFICATION_COLUMNS_CHANGED) &block(() -> UpdateColumns);
      BroadcastManager.subscribe(self) toBroadcast(Data.NOTIFICATION_VERBS_CHANGED) &block(() -> tableView.reloadData);
      UpdateColumns;
    end;

    //
    // NSTablewViewDataSource
    //

    method numberOfRowsInTableView(aTableView: NSTableView): NSInteger;
    begin
      result := visibleRows:Count;
    end;

    method tableView(aTableView: NSTableView) objectValueForTableColumn(aTableColumn: nullable NSTableColumn) row(aRow: NSInteger): nullable id;
    begin
      var conjugation := aTableColumn.identifier+visibleRows[aRow];
      result := verb.conjugationsByName[conjugation];
    end;

    method tableView(aTableView: NSTableView) setObjectValue(object: nullable id) forTableColumn(aTableColumn: nullable NSTableColumn) row(aRow: NSInteger);
    begin
      var conjugation := aTableColumn.identifier+visibleRows[aRow];
      var value := (object as String):ToLowerInvariant:Trim;

      if length(value) = 0 then
        value := nil;
      verb.conjugationsByName[conjugation] := value;
      Data.sharedInstance.updateVerb(verb);
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

      var conjugation := aTableColumn.identifier+visibleRows[aRow];

      var cell := aTableColumn.dataCell;
      cell.lineBreakMode := NSLineBreakMode.ByTruncatingTail;
      cell.font := NSFont.systemFontOfSize(11.0);
      cell.textColor := NSColor.textColor;

      cell.editable := true;
      if verb.conjugationsIsStandard[conjugation] then begin
        cell.textColor := NSColor.grayColor;
      end
      else begin
        cell.font := NSFont.boldSystemFontOfSize(11.0);
      end;

      if tableView.selectedRowIndexes.containsIndex(aRow) then
        cell.textColor := NSColor.selectedControlTextColor;
    end;

  private

    [IBOutlet]
    property tableView: NSTableView;
    property verb: Verb; readonly;
    property visibleColumns: List<String>;
    property visibleRows: List<String>;

    method UpdateColumns;
    begin
      visibleColumns := MainWindowController.FilterColumns(columns.ToList);
      visibleRows := MainWindowController.FilterRows(rows.ToList);
      Log($"visibleRows {visibleRows}");

      for each c in tableView.tableColumns.copy do
        tableView.removeTableColumn(c);

      for each c in visibleColumns do begin
        var column := new NSTableColumn();
        column.identifier := c;
        column.headerCell := new TallTableHeaderCell;
        column.headerCell.title := MainWindowController.FixHeader(c);
        column.title := MainWindowController.FixHeader(c);
        column.editable := true;
        column.minWidth := 100;
        tableView.addTableColumn(column);
      end;
      tableView.reloadData;
    end;

    //method FixHeader(aConfugation: String): String;
    //begin
      //result := aConfugation;
      //if result.StartsWith("Translation.") then
        //exit #10#10+result.SubstringFromFirstOccurrenceOf(".");

      //result := result.Replace("Affirmative", "Affirmative.").Replace("Negative", "Negative.");
      //result := result.Replace("1", "1st").Replace("2", "2nd").Replace("3", "3rd");

      //var lSplit := result.Split(".");
      //if lSplit.First = "Imperative" then case lSplit.Count of
        //3: exit lSplit.Reverse.JoinedString(#10);
        //2: exit #10+lSplit.Reverse.JoinedString(#10);
      //end;
      //result := case lSplit.Count of
        //4: lSplit[0]+"."+lSplit[3]+" "+lSplit[2]+"."+lSplit[1];
        //3: lSplit[2]+" "+lSplit[1]+"."+lSplit[0];
        //2: ".."+lSplit[1]+" "+lSplit[0];
        //1: ".."+lSplit[0]
      //end;
      //result := result.Replace(".", #10);
    //end;

    const columns : array of String = [
      "Indicativo.Present.",
      "Indicativo.Preterite.",
      "Indicativo.Imperfect.",
      "Indicativo.Conditional.",
      "Indicativo.Future.",

      "Subjuntivo.Present.",
      "Subjuntivo.Imperfect.",
      "Subjuntivo.Future.",
      ];

      const rows : array of String = [
      "Singular.1",
      "Singular.2",
      "Singular.3",
      "Plural.1",
      "Plural.2",
      "Plural.3",
      ];
  end;

end.