namespace Verbs;

type
  [IBObject]
  TableViewWithContextMenu = public class(NSTableView)
  private

    method menuForEvent(aEvent: not nullable NSEvent): NSMenu; public; override;
    begin
      inherited menuForEvent(aEvent);
      var lRow := rowAtPoint(convertPoint(aEvent.locationInWindow) fromView(nil));
      var lColumn := columnAtPoint(convertPoint(aEvent.locationInWindow) fromView(nil));
      if (lColumn > -1) and (lRow > -1) then
        if &delegate.respondsToSelector(selector(tableView:menuForTableColumn:row:)) then
          exit id(&delegate).tableView(self) menuForTableColumn(tableColumns[lColumn]) row(lRow);
    end;

  end;

  TallTableHeaderCell = public class(NSTableHeaderCell)
  public

    method drawWithFrame(cellFrame: NSRect) inView(controlView: NSView); override;
    begin
      drawInteriorWithFrame(cellFrame) inView(controlView);
    end;

  end;

end.