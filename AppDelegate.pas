namespace Verbs;

uses
  AppKit,
  Foundation;

type
  [NSApplicationMain, IBObject]
  AppDelegate = class(INSApplicationDelegate)
  public

    constructor;
    begin
      sharedInstance := self;
    end;

    class property sharedInstance: AppDelegate read private write;

    method applicationDidFinishLaunching(aNotification: NSNotification);
    begin
      fMainWindowController := new MainWindowController();
      fMainWindowController.showWindow(nil);
    end;

    property ShowTranslation: Boolean read boolForKey("ShowTranslation") withDefault(true) write begin setBool(value) forKey("ShowTranslation") end;
    property ShowParticiples: Boolean read boolForKey("ShowParticiples") withDefault(false) write begin setBool(value) forKey("ShowParticiples") end;
    property ShowImperatives: Boolean read boolForKey("ShowImperatives") withDefault(false) write begin setBool(value) forKey("ShowImperatives") end;

    property ShowIndicativo: Boolean read boolForKey("ShowIndicativo") withDefault(true) write begin setBool(value) forKey("ShowIndicativo") end;
    property ShowSubjuntivo: Boolean read boolForKey("ShowSubjuntivo") withDefault(false) write begin setBool(value) forKey("ShowSubjuntivo") end;

    property ShowIndicativeOrSubjunctive: Boolean read ShowIndicativo or ShowSubjuntivo;

    property ShowPresentTense: Boolean read boolForKey("ShowPresentTense") withDefault(true) write begin setBool(value) forKey("ShowPresentTense") end;
    property ShowPreteriteTense: Boolean read boolForKey("ShowPreteriteTense") withDefault(false) write begin setBool(value) forKey("ShowPreteriteTense") end;
    property ShowImperfectTense: Boolean read boolForKey("ShowImperfectTense") withDefault(false) write begin setBool(value) forKey("ShowImperfectTense") end;
    property ShowConditionalTense: Boolean read boolForKey("ShowConditionalTense") withDefault(true) write begin setBool(value) forKey("ShowConditionalTense") end;
    property ShowFutureTense: Boolean read boolForKey("ShowFutureTense") withDefault(true) write begin setBool(value) forKey("ShowFutureTense") end;

    property ShowVosAndVosotros: Boolean read boolForKey("ShowVosAndVosotros") withDefault(true) write begin setBool(value) forKey("ShowVosAndVosotros") end;

    const NOTIFICATION_COLUMNS_CHANGED = "com.dwarfland.verbs.columns.changed";

    [IBAction]
    method columnsChanged(aSender: id); public;
    begin
      BroadcastManager.submitBroadcast(NOTIFICATION_COLUMNS_CHANGED) object(nil) data(nil) syncToMainThread(true);
    end;

    [IBAction]
    method showWebsite(aSender: id); public;
    begin
      NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString("https://www.visionthing.cw/verbs.html"));
    end;

  private

    fMainWindowController: MainWindowController;

    method boolForKey(aKey: String) withDefault(aDefault: Boolean := false): Boolean;
    begin
      result := aDefault;
      if assigned(NSUserDefaults.standardUserDefaults.objectForKey(aKey)) then
        result := NSUserDefaults.standardUserDefaults.boolForKey(aKey)
    end;

    method setBool(aValue: Boolean) forKey(aKey: String);
    begin
      NSUserDefaults.standardUserDefaults.setBool(aValue) forKey(aKey);
    end;

  end;

end.