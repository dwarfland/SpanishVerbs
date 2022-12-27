namespace Verbs;

/*

  https://www.spanishdict.com/guide/stem-changing-verbs

*/
type
  Declination = public enum(Irregular, A, E, I);
  VerbStemChange = public enum(None, IE, UE, I);

  Verb = public class
  public

    constructor withInfinitive(aInfinitive: not nullable String);
    begin
      Infinitive := aInfinitive;
      if Infinitive.EndsWith("ar") then
        Declination := Declination.A
      else if Infinitive.EndsWith("er") then
        Declination := Declination.E
      else if Infinitive.EndsWith("ir") then
        Declination := Declination.I
      else
        Declination := Declination.Irregular;
    end;

    constructor withInfinitive(aInfinitive: not nullable String; aStemChange: VerbStemChange);
    begin
      constructor withInfinitive(aInfinitive);
      StemChange := aStemChange
    end;

    property Infinitive: String;
    property Declination: Declination := Declination.Irregular;
    property StemChange: VerbStemChange := VerbStemChange.None;

    property Stem: String read Infinitive.Substring(0, length(Infinitive)-2);
    property StemPlusVowel: String read Infinitive.Substring(0, length(Infinitive)-1);
    property StemVowel: String read case Declination of
        Declination.A: "a";
        Declination.E: "e";
        Declination.I: "e";
      end;

    property ChangedStem: String read begin
      result := Stem;
      if StemChange ≠ VerbStemChange.None then begin
        for i := length(result)-1 downto 0 do begin
          if result[i] in ['e','o','i'/*,'u'*/] then begin
            result := result.Replace(i, 1, StemChangeToString(StemChange));
            break;
          end;
        end;
      end;

    end;

    property conjugationsByName[aName: not nullable String]: nullable String
      read get_ConjugationsByName write fConjugationsByName[aName];

    property conjugationsIsStandard[aName: not nullable String]: Boolean
      read not assigned(fConjugationsByName[aName]);

    method ToXml: XmlElement;
    begin
      result := new XmlElement withName("Verb");
      result.SetAttribute("Infinitive", nil, Infinitive);
      if StemChange ≠ VerbStemChange.None then
        result.SetAttribute("StemChange", nil, StemChangeToString(StemChange).ToUpperInvariant);
      if Declination = Declination.Irregular then
        result.SetAttribute("Declination", nil, "Irregular");
      for each k in fConjugationsByName.Keys.OrderBy(k -> k) do
        result.AddElement(k, nil, fConjugationsByName[k]);
    end;

    constructor fromXml(aXml: XmlElement);
    begin
      constructor withInfinitive(aXml.Attribute["Infinitive"].Value);
      case caseInsensitive(aXml.Attribute["StemChange"]:Value) of
        "I": StemChange := VerbStemChange.I;
        "IE": StemChange := VerbStemChange.IE;
        "UE": StemChange := VerbStemChange.UE;
      end;
      case caseInsensitive(aXml.Attribute["Declination"]:Value) of
        "Irregular": Declination := Declination.Irregular;
      end;
      for each e in aXml.Elements do
        fConjugationsByName[e.LocalName] := e.Value;
    end;

  private

    var fConjugationsByName := new Dictionary<String,String>;

    method get_ConjugationsByName(aName: String): String;
    begin
      if aName = "Infinitive" then
        exit Infinitive;

      result := fConjugationsByName[aName];
      if assigned(result) then
        exit;

      var lSplit := aName.Split(".");
      if lSplit.Count ≥ 0 then begin
        result := case lSplit[0] of
          "Participle": getParticiple(lSplit[1]);
          "Imperative": getImperative(lSplit[1]);
          "Indicativo": getIndicativo(lSplit.Skip(1).ToList);
          else nil;
        end;
      end;

    end;

    method set_ConjugationsByName(aName: String; aValue: String);
    begin
      if aName = "Infinitive" then
        exit;
    end;

    //
    //
    //

    // https://www.spanishdict.com/guide/present-participles-in-spanish

    method getParticiple(aType: String): String;
    begin
      if Declination in [Declination.A, Declination.E, Declination.I] then begin
        case aType of
          "Present": begin
              var lStem := if Declination = Declination.I then ChangedStem else Stem;
              if (length(lStem) = 0) then
                result := "yendo"
              else if (Declination in [Declination.E, Declination.I]) and (lStem.Last in ['a', 'e', 'i', 'o', 'u']) then
                result := lStem+"yendo"
              else if Declination in [Declination.E, Declination.I] then
                result := lStem+"iendo"
              else
                result := lStem+StemVowel+"ndo";
            end;
          "Past": begin
            end;
        end;
      end;
    end;


    method getImperative(aCount: String): String;
    begin
      if aCount in ["Singular", "Plural"] then begin
        result := conjugationsByName["Indicativo.Present.Singular.3"];
        if assigned(result) and (aCount = "Plural") then begin
          var lLastChar := result.Substring(length(result)-1);
          lLastChar := case lLastChar of
            "a": "e";
            "e": "a";
          end;
          result := result.Substring(0, length(result)-1)+lLastChar;
        end;
      end;

    end;

    method getIndicativo(aSplit: List<String>): String;
    begin
      if aSplit.Count ≥ 0 then begin
        result := case aSplit[0] of
          "Present": getIndicativoPresent(aSplit.Skip(1).ToList);
          "Past": getIndicativoPast(aSplit.Skip(1).ToList);
          else nil;
        end;
      end;
    end;

    // https://www.spanishdict.com/guide/spanish-present-tense-forms
    // https://www.spanishdict.com/guide/spanish-irregular-present-tense

    method getIndicativoPresent(aSplit: List<String>): String;
    begin
      if (aSplit.Count = 2) then begin

        case aSplit[0] of
          "Singular": case aSplit[1] of
            "1": begin
                if Infinitive.EndsWith("guir")then //, the yo form ends in go.
                  result := ChangedStem.Substring(0, length(ChangedStem)-2)+"go"
                else if Infinitive.EndsWith("ger") or Infinitive.EndsWith("gir") then //, the g in the yo form changes to a j.
                  result := ChangedStem.Substring(0, length(ChangedStem)-1)+"jo"

                else
                  result := ChangedStem+"o";
              end;
            "2": result := ChangedStem+StemVowel+"s";
            "3": result := ChangedStem+StemVowel;
          end;
          "Plural": case aSplit[1] of
            "1": result := StemPlusVowel+"mos"; // no stem change *and* no vowel change for 1st plural
            //"2": result := StemPlusVowel+"s";
            "3": result := ChangedStem+StemVowel+"n";
          end;
        end;
      end;
    end;

    method getIndicativoPast(aSplit: List<String>): String;
    begin
    end;

  end;

method StemChangeToString(aStemChange: VerbStemChange): String;
begin
  result := case aStemChange of
    VerbStemChange.I: "i";
    VerbStemChange.IE: "ie";
    VerbStemChange.UE: "ue";
  end;
end;

end.