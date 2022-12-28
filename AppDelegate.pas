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

    [Notify] property ShowTranslation: Boolean := true;
    [Notify] property ShowParticiples: Boolean := false;
    [Notify] property ShowImperatives: Boolean := false;

    [Notify] property ShowIndicativo: Boolean := true;
    [Notify] property ShowSubjuntivo: Boolean := false;

    property ShowIndicativeOrSubjunctive: Boolean read ShowIndicativo or ShowSubjuntivo;

    [Notify] property ShowPresentTense: Boolean := true;
    [Notify] property ShowPreteriteTense: Boolean := false;
    [Notify] property ShowImperfectTense: Boolean := false;
    [Notify] property ShowPerfectTense: Boolean := false;
    [Notify] property ShowSimpleFutureTense: Boolean := true;

    [Notify] property ShowVosAndVosotros: Boolean := true;

  private

    fMainWindowController: MainWindowController;

  end;

end.