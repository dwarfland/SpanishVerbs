namespace Verbs;

/*

  https://www.spanishdict.com/guide/stem-changing-verbs

*/
type
  Declination = public enum(Irregular, A, E, I);
  VerbStemChange = public enum(None, IE, UE, I);
  VerbIrSpill = public enum(None, EToI, OToU);

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

    property Local: Boolean;
    property ChangedLocally: Boolean;

    property Infinitive: String;
    property Declination: Declination := Declination.Irregular;
    property StemChange: VerbStemChange := VerbStemChange.None;
    property IrSpill: VerbIrSpill := VerbIrSpill.None;
    property AdjustCZ: Boolean;

    property Stem: String read Infinitive.Substring(0, length(Infinitive)-2);
    property StemPlusVowel: String read Infinitive.Substring(0, length(Infinitive)-1);

    property AdjustedVowel_Present: String read case Declination of
        Declination.A: "a";
        Declination.E: "e";
        Declination.I: "e";
      end;

    property AdjustedVowel_Subjuntivo: String read case Declination of
        Declination.A: "e";
        Declination.E: "a";
        Declination.I: "a";
      end;

    property PresentVosotros: String read case Declination of
        Declination.A: "áis";
        Declination.E: "éis";
        Declination.I: "ís";
      end;

    [Obsolete("Just use Stem, once all is good. i just wanna remember what used ChangedStem before")]
    property UnchangedStem: String read Stem;

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

    property JStem: String read begin
      result := Stem;
      if result.EndsWith("c") then
        result := result.Substring(0, length(Stem)-1)+"j";
    end;

    property ChangedStemForIrSpill: String read begin
      result := Stem;
      if (IrSpill ≠ VerbIrSpill.None) and (Declination = Declination.I) then begin
        for i := length(result)-1 downto 0 do begin
          case IrSpill of
            VerbIrSpill.EToI: if result[i] in ['e'] then begin
              result := result.Replace(i, 1, 'i');
              break;
            end;
            VerbIrSpill.OToU: if result[i] in ['o'] then begin
                result := result.Replace(i, 1, 'u');
                break;
              end;
          end;
        end;
      end;
    end;

    //property ChangedStemForSpelling: String read begin
      //result := Stem;
      //if Infinitive.EndsWith("car") then begin
        //result := Stem.Substring(0, length(Stem)-1)+"qu";
      //end
      //else if Infinitive.EndsWith("gar") then begin
        //result := Stem.Substring(0, length(Stem)-1)+"gu";
      //end;
      //if Infinitive.EndsWith("zar") then begin
        //result := Stem.Substring(0, length(Stem)-1)+"c";
      //end;
    //end;

    property SubjuntivoStem: String read begin
      result := rawConjugationsByName["Indicativo.Present.Singular.1"];
      if length(result) > 0 then
        result := result.Substring(0, length(result)-1); // subjunctive stem = yo form of present indicative minus o ending
    end;

    property SubjuntivoImperfectStem: String read begin
      result := rawConjugationsByName["Indicativo.Preterite.Plural.3"];
      if length(result) > 3 then // always will be, but jic
        result := result.Substring(0, length(result)-3); // Instead of using the infinitive for a stem, the imperfect subjunctive uses the third person plural of the preterite (minus the -ron)
    end;

    property conjugationsByName[aName: not nullable String]: nullable String
      read get_ConjugationsByName write fConjugationsByName[aName];

    property rawConjugationsByName[aName: not nullable String]: nullable String
      read get_RawConjugationsByName write fConjugationsByName[aName];

    property localConjugations: ImmutableList<String> read fConjugationsByName.Keys;

    property conjugationsIsStandard[aName: not nullable String]: Boolean
      read not assigned(fConjugationsByName[aName]);

    method ToXml: XmlElement;
    begin
      result := new XmlElement withName("Verb");
      result.SetAttribute("Infinitive", nil, Infinitive);
      if StemChange ≠ VerbStemChange.None then
        result.SetAttribute("StemChange", nil, StemChangeToString(StemChange).ToUpperInvariant);
      if IrSpill ≠ VerbIrSpill.None then
        result.SetAttribute("IrSpill", nil, IrSpillToString(IrSpill));
      if AdjustCZ then
        result.SetAttribute("AdjustZC", nil, "True");
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
      case caseInsensitive(aXml.Attribute["IrSpill"]:Value) of
        "EToI", "e -> i": IrSpill := VerbIrSpill.EToI;
        "OToU", "o -> u": IrSpill := VerbIrSpill.OToU;
      end;
      case caseInsensitive(aXml.Attribute["AdjustZC"]:Value) of
        "True": AdjustCZ := true;
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
      //result := fConjugationsByName[aName];
      //if assigned(result) then
        //exit;

      result := rawConjugationsByName[aName];

      if StemChange ≠ VerbStemChange.None then begin
        case aName of
          //Imperatives already have the stem change
          //"Imperative.Tu",
          //"Imperative.Usted",
          //"Imperative.Ustedes",
          "Indicativo.Present.Singular.1",
          "Indicativo.Present.Singular.2",
          "Indicativo.Present.Singular.3",
          "Indicativo.Present.Plural.3",
          "Subjuntivo.Present.Singular.1",
          "Subjuntivo.Present.Singular.2",
          "Subjuntivo.Present.Singular.3",
          "Subjuntivo.Present.Plural.3":
            result := ChangeStem(result);
        end;
      end;

      if IrSpill ≠ VerbIrSpill.None then begin
        case aName of
          //"Gerundio",
          "Imperative.Usted",
          "Imperative.Nosotros",
          "Indicativo.Preterite.Singular.3",
          "Indicativo.Preterite.Plural.3",
          "Subjuntivo.Present.Plural.1",
          "Subjuntivo.Present.Plural.2":
            result := ChangeStemForIrSpill(result);
        end;
      end;

      if Infinitive.EndsWith("car") then begin
        case aName of
          //"Imperative.Usted",
          //"Imperative.Ustedes",
          //"Imperative.Nosotros",
          "Indicativo.Preterite.Singular.1",
          "Subjuntivo.Present.Singular.1",
          "Subjuntivo.Present.Singular.2",
          "Subjuntivo.Present.Singular.3",
          "Subjuntivo.Present.Plural.1",
          "Subjuntivo.Present.Plural.2",
          "Subjuntivo.Present.Plural.3": begin
              //Log($"{Infinitive}, {result} ({aName}) => {ChangeStemForSpelling(result)}");
              result := ChangeStemForSpelling(result);
              //Log($"result {result}");
            end;
        end;
      end;

      if Infinitive.EndsWith("gar") or Infinitive.EndsWith("zar") then begin
        case aName of
          //  •  All imperatives that use subj as source
          //"Imperative.Ustedes",
          //"Imperative.Usted",
          //"Imperative.Plural",
          //"Imperative.Nosotros",
          //"Imperative.NegativeVosotros",
          //"Imperative.NegativeVos",
          "Indicativo.Preterite.Singular.1",
          "Subjuntivo.Present.Singular.1",
          "Subjuntivo.Present.Singular.2",
          "Subjuntivo.Present.Singular.3",
          "Subjuntivo.Present.Plural.1",
          "Subjuntivo.Present.Plural.2",
          "Subjuntivo.Present.Plural.3": begin
              //Log($"{Infinitive}, {result} ({aName}) => {ChangeStemForSpelling(result)}");
              result := ChangeStemForSpelling(result);
            end;
        end;
      end;

      if Infinitive.EndsWith("uir") and not Infinitive.EndsWith("guir") then begin
        case aName of
          "Indicativo.Present.Singular.1",
          "Indicativo.Present.Singular.2",
          "Indicativo.Present.Singular.3",
          "Indicativo.Present.Plural.3",
          "Indicativo.Preterite.Singular.3",
          "Indicativo.Preterite.Plural.3",
          "Subjuntivo.Present.Singular.1",
          "Subjuntivo.Present.Singular.2",
          "Subjuntivo.Present.Singular.3",
          "Subjuntivo.Present.Plural.1",
          "Subjuntivo.Present.Plural.2",
          "Subjuntivo.Present.Plural.3":
            //Log($"ChangeStemForIToY({result} -> {ChangeStemForIToY(result)}");
            result := ChangeStemForIToY(result);
        end;
      end;

      if AdjustCZ then begin
        case aName of
          "Indicativo.Present.Singular.1",
          "Subjuntivo.Present.Singular.1",
          "Subjuntivo.Present.Singular.2",
          "Subjuntivo.Present.Singular.3",
          "Subjuntivo.Present.Plural.1",
          "Subjuntivo.Present.Plural.2",
          "Subjuntivo.Present.Plural.3":
            result := ChangeStemForCZ(result);
        end;
      end;

      with matching lOverride := fConjugationsByName[aName] do begin

        //if lOverride = result then
          //Log($"Unnecessary manual override {lOverride}");
        //else
          //Log($"            manual overide {result} => {lOverride}");
        result := lOverride;

      end;
    end;

    method ChangeStem(aVerb: String): String;
    begin
      if StemChange ≠ VerbStemChange.None then
        if aVerb.StartsWith(Stem) then
          exit ChangedStem+aVerb.Substring(length(Stem));
      result := aVerb;
    end;

    method ChangeStemForIrSpill(aVerb: String): String;
    begin
      if IrSpill ≠ VerbIrSpill.None then
        if aVerb.StartsWith(Stem) then
          exit ChangedStemForIrSpill+aVerb.Substring(length(Stem));
      result := aVerb;
    end;

    method ChangeStemForSpelling(aVerb: String): String;
    begin

      method FixAt(aIndex: Integer): String;
      begin
        var lReplacement := if Infinitive.EndsWith("car") then "qu"
        else if Infinitive.EndsWith("gar") then "gu"
        else if Infinitive.EndsWith("zar") then "c";
        result := aVerb.Substring(0, aIndex-1)+lReplacement+aVerb.Substring(aIndex);
      end;

      if aVerb.StartsWith(Stem) then begin
        if length(aVerb) > length(Stem) then
          if aVerb[length(Stem)] in ['e', 'é', 'i', 'í'] then
            exit FixAt(length(Stem));
      end
      else if aVerb.StartsWith(ChangedStem) then begin
        if length(aVerb) > length(ChangedStem) then
          if aVerb[length(ChangedStem)] in ['e', 'é', 'i', 'í'] then
            exit FixAt(length(ChangedStem));
      end;
      result := aVerb;
    end;

    method ChangeStemForIToY(aVerb: String): String;
    begin
      if aVerb:StartsWith(Stem) then begin
        if length(aVerb) > length(Stem) then
          if aVerb[length(Stem)] in ['a','e','i','o','u','á','é','í','ó','ú'] then
            exit Stem.Substring(0, length(Stem)) + "y" + aVerb.Substring(Stem.Length);
      end
      else if aVerb:StartsWith(ChangedStem) then begin
        if length(aVerb) > length(ChangedStem) then
          if aVerb[length(ChangedStem)] in ['a','e','i','o','u','á','é','í','ó','ú'] then
            exit ChangedStem.Substring(0, length(ChangedStem)) + "y" + aVerb.Substring(ChangedStem.Length);
      end;
      result := aVerb;
    end;

    method ChangeStemForCZ(aVerb: String): String;
    begin
      if aVerb:StartsWith(Stem) then begin
        if length(aVerb) > length(Stem) then
          exit Stem.Substring(0, length(Stem)-1) + "zc" + aVerb.Substring(Stem.Length);
      end
      else if aVerb:StartsWith(ChangedStem) then begin
        if length(aVerb) > length(ChangedStem) then
          exit ChangedStem.Substring(0, length(ChangedStem)-1) + "zc" + aVerb.Substring(ChangedStem.Length);
      end;
      result := aVerb;
    end;

    //
    //
    //

    method get_RawConjugationsByName(aName: String): String;
    begin

      if (Infinitive = "ser") and (aName = "Participle.Past") then
        getParticiple("Past");

      if Infinitive.Contains("*") and (not aName.StartsWith("Translation.")) then begin
        var lSplit := Infinitive.SplitAtFirstOccurrenceOf("*");
        var lVerb := Data.sharedInstance.verbsByInfinitive[lSplit[1]];
        if assigned(lVerb) then
          exit lSplit[0]+lVerb.conjugationsByName[aName]
        else
          exit #"[{Infinitive}]";
      end;

      if aName = "Infinitive" then
        exit Infinitive;

      //result := fConjugationsByName[aName];
      //if assigned(result) then
        //exit;

      var lSplit := aName.Split(".");
      if lSplit.Count ≥ 0 then begin
        result := case lSplit[0] of
          "Participle": getParticiple(lSplit[1]);
          "Imperative": getImperative(lSplit[1]);
          "Indicativo": getIndicativo(lSplit.Skip(1).ToList);
          "Subjuntivo": getSubjuntivo(lSplit.Skip(1).ToList);
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
              var lStem := if Declination = Declination.I then UnchangedStem else Stem;
              if (length(lStem) = 0) then
                result := "yendo"
              else if (Declination in [Declination.E, Declination.I]) and (lStem.Last in ['a', 'e', 'i', 'o', 'u']) then
                result := lStem+"yendo"
              else if Declination in [Declination.E, Declination.I] then
                result := lStem+"iendo"
              else
                result := lStem+AdjustedVowel_Present+"ndo";
            end;
          "Past": begin
              result := Stem+case Declination of
                  Declination.A: "ado";
                  Declination.E,
                  Declination.I: "ido";
                end;
            end;
        end;
      end;
    end;

    // https://www.spanishdict.com/guide/commands

    method getImperative(aCount: String): String;
    begin
      case aCount of
        "Tu", "Tú", "Singular": result := conjugationsByName["Indicativo.Present.Singular.3"];
        "Usted", "Plural": result := conjugationsByName["Subjuntivo.Present.Singular.3"]; // To form both affirmative and negative usted commands, use the third-person singular form of the present subjunctive.
            //{$HINT later: use the third-person singular form of the present subjunctive.}
            //result := conjugationsByName["Indicativo.Present.Singular.3"];
            //var lLastChar := result.Substring(length(result)-1);
            //lLastChar := case lLastChar of
              //"a": "e";
              //"e": "a";
            //end;
            //result := result.Substring(0, length(result)-1)+lLastChar;
          //end;
        "Ustedes": result := conjugationsByName["Subjuntivo.Present.Plural.3"]; // To form both affirmative and negative ustedes commands, use the third-person plural form of the present subjunctive.
        "Nosotros": result := conjugationsByName["Subjuntivo.Present.Plural.1"];// To form both affirmative and negative nosotros commands, use the nosotros form of the present subjunctive.
        "AffirmativeVosotros": result := Infinitive.Substring(0, length(Infinitive)-1)+"d"; // To form affirmative vosotros commands, replace the ‐r at the end of the infinitive with a ‐d.
        "NegativeVosotros": result := "no "+conjugationsByName["Subjuntivo.Present.Plural.2"]; // To form negative vosotros commands, use the vosotros form of the present subjunctive.
        "AffirmativeVos": result := Infinitive.Substring(0, length(Infinitive)-1).AddAccentToLastChar; // To form affirmative vos commands, drop the -r from the end of the infinitive and add an accent on the last vowel.
        "NegativeVos": result := "no "+conjugationsByName["Subjuntivo.Present.Singular.2"]; // To form negative vos commands, use the tú form of the present subjunctive.
      end;
    end;

    method getIndicativo(aSplit: List<String>): String;
    begin
      if aSplit.Count ≥ 0 then begin
        result := case aSplit[0] of
          "Present": getIndicativoPresent(aSplit.Skip(1).ToList);
          "Preterite": getIndicativoPreterite(aSplit.Skip(1).ToList);
          "Imperfect": getIndicativoImperfect(aSplit.Skip(1).ToList);
          "Conditional": getIndicativoConditional(aSplit.Skip(1).ToList);
          "Future": getIndicativoSimpleFuture(aSplit.Skip(1).ToList);
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
                  result := UnchangedStem.Substring(0, length(UnchangedStem)-2)+"go"
                else if Infinitive.EndsWith("ger") or Infinitive.EndsWith("gir") then //, the g in the yo form changes to a j.
                  result := UnchangedStem.Substring(0, length(UnchangedStem)-1)+"jo"

                else
                  result := UnchangedStem+"o";
              end;
            "2": result := UnchangedStem+AdjustedVowel_Present+"s";
            "3": result := UnchangedStem+AdjustedVowel_Present;
          end;
          "Plural": case aSplit[1] of
            "1": result := StemPlusVowel+"mos"; // no stem change *and* no vowel change for 1st plural
            "2": result := Stem+PresentVosotros;
            "3": result := UnchangedStem+AdjustedVowel_Present+"n";
          end;
        end;
      end;
    end;

    // https://www.spanishdict.com/guide/spanish-preterite-tense-forms

    method getIndicativoPreterite(aSplit: List<String>): String;
    begin
      if (aSplit.Count = 2) then begin

        if Infinitive.EndsWith("ducir") /*or AdjustJ*/ then begin
          case aSplit[0] of
            "Singular": case aSplit[1] of
              "1": exit JStem + "e";
              "2": exit JStem + "iste";
              "3": exit JStem + "o";
            end;
            "Plural": case aSplit[1] of
              "1": exit JStem + "imos";
              "2": exit JStem + "isteis";
              "3": exit JStem + "eron";
            end;
          end;
        end;

        case aSplit[0] of
          "Singular": case aSplit[1] of
            "1": result := UnchangedStem+case Declination of
                    Declination.A: "é";
                    Declination.E: "í";
                    Declination.I: "í";
                  end;
            "2": result := UnchangedStem+case Declination of
                    Declination.A: "aste";
                    Declination.E: "iste";
                    Declination.I: "iste";
                  end;
            "3": result := UnchangedStem+case Declination of
                    Declination.A: "ó";
                    Declination.E: "ió";
                    Declination.I: "ió";
                  end;
          end;
          "Plural": case aSplit[1] of
            "1": result := StemPlusVowel+"mos"; // same as present!?
            "2": result := UnchangedStem+case Declination of
                    Declination.A: "asteis";
                    Declination.E: "isteis";
                    Declination.I: "isteis";
                  end;
            "3": result := UnchangedStem+case Declination of
                    Declination.A: "aron";
                    Declination.E: "ieron";
                    Declination.I: "ieron";
                  end;
          end;
        end;
      end;
    end;

    // https://www.spanishdict.com/guide/spanish-imperfect-tense-forms

    method getIndicativoImperfect(aSplit: List<String>): String;
    begin
      if Declination in [Declination.A, Declination.E, Declination.I] then begin

        if (aSplit.Count = 2) then begin
          case aSplit[0] of
            "Singular": case aSplit[1] of
              "1": result := Stem+case Declination of
                  Declination.A: "aba";
                  Declination.E: "ía";
                  Declination.I: "ía";
                end;
              "2": result := Stem+case Declination of
                  Declination.A: "abas";
                  Declination.E: "ías";
                  Declination.I: "ías";
                end;
              "3": result := Stem+case Declination of
                  Declination.A: "aba";
                  Declination.E: "ía";
                  Declination.I: "ía";
                end;
              end;
            "Plural": case aSplit[1] of
              "1": result := Stem+case Declination of
                  Declination.A: "ábamos";
                  Declination.E: "íamos";
                  Declination.I: "íamos";
                end;
              "2": result := Stem+case Declination of
                  Declination.A: "abais";
                  Declination.E: "íais";
                  Declination.I: "íais";
                end;
              "3": result := Stem+case Declination of
                  Declination.A: "aban";
                  Declination.E: "ían";
                  Declination.I: "ían";
                end;
            end;
          end;
        end;
      end;
    end;

    method getIndicativoSimpleFuture(aSplit: List<String>): String;
    begin
      if (aSplit.Count = 2) then begin
        case aSplit[0] of
          "Singular": case aSplit[1] of
              "1": result := Infinitive+"é";
              "2": result := Infinitive+"ás";
              "3": result := Infinitive+"á";
            end;
          "Plural": case aSplit[1] of
              "1": result := Infinitive+"emos";
              "2": result := Infinitive+"éis";
              "3": result := Infinitive+"án";
            end;
        end;
      end;
    end;

    // https://www.spanishdict.com/guide/conditional-tense

    method getIndicativoConditional(aSplit: List<String>): String;
    begin
      var lStem := Infinitive;
      if lStem in ["tener", "poner", "valer", "salir", "venir"] then
        lStem := Stem+"dr";
      if lStem in ["poder", "caber", "haber", "querer", "saber"] then
        lStem := Stem+"r";
      if (aSplit.Count = 2) then begin
        case aSplit[0] of
          "Singular": case aSplit[1] of
            "1": result := lStem+"ía";
            "2": result := lStem+"ías";
            "3": result := lStem+"ía";
          end;
          "Plural": case aSplit[1] of
            "1": result := lStem+"íamos";
            "2": result := lStem+"íais";
            "3": result := lStem+"ían";
          end;
        end;
      end;
    end;

    //
    //
    //

    method getSubjuntivo(aSplit: List<String>): String;
    begin
      if aSplit.Count ≥ 0 then begin
        result := case aSplit[0] of
          "Present": getSubjuntivoPresent(aSplit.Skip(1).ToList);
          "Imperfect": getSubjuntivo1Imperfect(aSplit.Skip(1).ToList); // we only use Subjuntivo 1, for now
          "Future": getSubjuntivoFuture(aSplit.Skip(1).ToList);
          else nil;
        end;
      end;
    end;

    // https://www.spanishdict.com/guide/spanish-present-subjunctive

    method getSubjuntivoPresent(aSplit: List<String>): String;
    begin
      if (aSplit.Count = 2) then begin
        case aSplit[0] of
          "Singular": case aSplit[1] of
            "1": result := SubjuntivoStem+AdjustedVowel_Subjuntivo;
            "2": result := SubjuntivoStem+AdjustedVowel_Subjuntivo+"s";
            "3": result := SubjuntivoStem+AdjustedVowel_Subjuntivo;
          end;
          "Plural": case aSplit[1] of
            "1": result := SubjuntivoStem+AdjustedVowel_Subjuntivo+"mos";
            "2": result := SubjuntivoStem+case Declination of
                    Declination.A: "éis";
                    Declination.E: "áis";
                    Declination.I: "áis";
                  end;
            "3": result := SubjuntivoStem+AdjustedVowel_Subjuntivo+"n";
          end;
        end;
      end;
    end;

    // https://www.spanishdict.com/guide/spanish-imperfect-subjunctive

    method getSubjuntivo1Imperfect(aSplit: List<String>): String;
    begin
      if (aSplit.Count = 2) then begin
        case aSplit[0] of
          "Singular": case aSplit[1] of
            "1": result := SubjuntivoImperfectStem+"ra";
            "2": result := SubjuntivoImperfectStem+"ras";
            "3": result := SubjuntivoImperfectStem+"ra";
          end;
          "Plural": case aSplit[1] of
            "1": result := SubjuntivoImperfectStem.AddAccentToLastChar+"ramos";
            "2": result := SubjuntivoImperfectStem+"rais";
            "3": result := SubjuntivoImperfectStem+"ran";
          end;
        end;
      end;
    end;

    method getSubjuntivo2Imperfect(aSplit: List<String>): String;
    begin
      if (aSplit.Count = 2) then begin
        case aSplit[0] of
          "Singular": case aSplit[1] of
            "1": result := SubjuntivoImperfectStem+"se";
            "2": result := SubjuntivoImperfectStem+"ses";
            "3": result := SubjuntivoImperfectStem+"se";
          end;
          "Plural": case aSplit[1] of
            "1": result := SubjuntivoImperfectStem.AddAccentToLastChar+"semos";
            "2": result := SubjuntivoImperfectStem+"seis";
            "3": result := SubjuntivoImperfectStem+"sen";
          end;
        end;
      end;

    end;

    // https://www.spanishdict.com/guide/spanish-future-subjunctive

    method getSubjuntivoFuture(aSplit: List<String>): String;
    begin
      if (aSplit.Count = 2) then begin
        case aSplit[0] of
          "Singular": case aSplit[1] of
            "1": result := SubjuntivoImperfectStem+"re";
            "2": result := SubjuntivoImperfectStem+"res";
            "3": result := SubjuntivoImperfectStem+"re";
          end;
          "Plural": case aSplit[1] of
            "1": result := SubjuntivoImperfectStem.AddAccentToLastChar+"remos";
            "2": result := SubjuntivoImperfectStem+"reis";
            "3": result := SubjuntivoImperfectStem+"ren";
          end;
        end;
      end;
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

method IrSpillToString(aIrSpill: VerbIrSpill): String;
begin
  result := case aIrSpill of
    VerbIrSpill.EToI: "e -> i";
    VerbIrSpill.OToU: "o -> u";
  end;
end;

end.