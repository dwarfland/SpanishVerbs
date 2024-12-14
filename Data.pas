namespace Verbs;

type
  Data = public class
  public

    class property sharedInstance: InstanceType := new Data; readonly;

    property verbs: List<Verb> read private write;
    property defaultVerbs: List<Verb> read private write;
    property dataFileName: String; private;

    property verbsByInfinitive := new Dictionary<String,Verb>;
    property defaultVerbsByInfinitive := new Dictionary<String,Verb>;

    method ping; empty;

    method reload;
    begin
      var defaultDataFile := NSBundle.mainBundle.URLForResource("DefaultVerbs.Spanish") withExtension("xml") as Url;
      if defaultDataFile:FileExists then
        defaultVerbs := Load(defaultDataFile.FilePath);
      for each v in defaultVerbs do
        defaultVerbsByInfinitive[v.Infinitive] := v;

      dataFileName := Path.Combine(Environment.UserApplicationSupportFolder, "Dwarfland", "Verbs.Spanish.xml");
      Log($"dataFileName {dataFileName}");
      if dataFileName.FileExists then begin
        verbs := Load;
        for each v in verbs do
          verbsByInfinitive[v.Infinitive] := v;
        for each v in verbs do
          if not assigned(defaultVerbsByInfinitive[v.Infinitive]) then
            v.Local := true;
      end
      else begin
        verbs := defaultVerbs.UniqueMutableCopy;
        verbsByInfinitive := defaultVerbsByInfinitive.UniqueMutableCopy;
      end;
    end;

    method save;
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
      for each v in verbs.OrderBy(v -> v.Infinitive) do
        xml.Root.Add(v.ToXml);
      Folder.Create(dataFileName.ParentDirectory);
      xml.SaveToFile(dataFileName, XmlStyleVisualStudio);
    end;

    method updateFromDefault: tuple of (Integer, Integer);
    begin
      var newCount, updatedCount: Integer;
      for each v in defaultVerbs do begin
        if not assigned(verbsByInfinitive[v.Infinitive]) then begin
          verbs.Add(v);
          verbsByInfinitive[v.Infinitive] := v;
          inc(newCount);
        end;
      end;
      if (newCount > 0) or (updatedCount > 0) then
        save();
      result := (newCount, updatedCount);
    end;

    method addVerb(aVerb: Verb);
    begin
      verbs.Add(aVerb);
      verbsByInfinitive[aVerb.Infinitive] := aVerb;
      aVerb.Local := true;
      save();
    end;

    method updateVerb(aVerb: Verb);
    begin
      aVerb.ChangedLocally := true;
      save();
      BroadcastManager.submitBroadcast(NOTIFICATION_VERBS_CHANGED) object(nil) data(nil) syncToMainThread(true);
    end;

    const NOTIFICATION_VERBS_CHANGED = "com.dwarfland.verbs.verbs.changed";

  private

    constructor;
    begin
      reload;
    end;

    method Load(aFilenameOverride: nullable String := nil): List<Verb>;
    begin
      result := new List<Verb>;
      var xml := XmlDocument.TryFromFile(coalesce(aFilenameOverride, dataFileName));
      for each e in xml.Root.ElementsWithName("Verb") do
        result.Add(new Verb fromXml(e));
    end;

  end;

end.