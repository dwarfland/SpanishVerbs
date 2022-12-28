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

    property SubjuntivoStem: String read begin
      result := conjugationsByName["Indicativo.Present.Singular.3"];
      if length(result) > 0 then
        result := result.Substring(0, length(result)-1); // subjunctive stem = yo form of present indicative minus o ending
    end;

    property SubjuntivoImperfectStem: String read begin
      result := conjugationsByName["Indicativo.Preterite.Singular.3"];
      if length(result) > 3 then // always will bem, but jic
        result := result.Substring(0, length(result)-3); // Instead of using the infinitive for a stem, the imperfect subjunctive uses the third person plural of the preterite (minus the -ron)
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
              var lStem := if Declination = Declination.I then ChangedStem else Stem;
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
        "NegativeVosotros": result := conjugationsByName["Subjuntivo.Present.Plural.2"]; // To form negative vosotros commands, use the vosotros form of the present subjunctive.
        "AffirmativeVos": result := Infinitive.Substring(0, length(Infinitive)-1).AddAccentToLastChar; // To form affirmative vos commands, drop the -r from the end of the infinitive and add an accent on the last vowel.
        "NegativeVos": result := conjugationsByName["Subjuntivo.Present.Singular.2"]; // To form negative vos commands, use the tú form of the present subjunctive.
      end;
    end;

    method getIndicativo(aSplit: List<String>): String;
    begin
      if aSplit.Count ≥ 0 then begin
        result := case aSplit[0] of
          "Present": getIndicativoPresent(aSplit.Skip(1).ToList);
          "Preterite": getIndicativoPreterite(aSplit.Skip(1).ToList);
          "Imperfect": getIndicativoImperfect(aSplit.Skip(1).ToList);
          "SimpleFuture": getIndicativoSimpleFuture(aSplit.Skip(1).ToList);
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
            "2": result := ChangedStem+AdjustedVowel_Present+"s";
            "3": result := ChangedStem+AdjustedVowel_Present;
          end;
          "Plural": case aSplit[1] of
            "1": result := StemPlusVowel+"mos"; // no stem change *and* no vowel change for 1st plural
            "2": result := Stem+PresentVosotros;
            "3": result := ChangedStem+AdjustedVowel_Present+"n";
          end;
        end;
      end;
    end;

    // https://www.spanishdict.com/guide/spanish-preterite-tense-forms

    method getIndicativoPreterite(aSplit: List<String>): String;
    begin
      if (aSplit.Count = 2) then begin
        case aSplit[0] of
          "Singular": case aSplit[1] of
            "1": result := ChangedStem+case Declination of
                    Declination.A: "é";
                    Declination.E: "í";
                    Declination.I: "í";
                  end;
            "2": result := ChangedStem+case Declination of
                    Declination.A: "aste";
                    Declination.E: "iste";
                    Declination.I: "iste";
                  end;
            "3": result := ChangedStem+case Declination of
                    Declination.A: "ó";
                    Declination.E: "ío";
                    Declination.I: "í";
                  end;
          end;
          "Plural": case aSplit[1] of
            "1": result := StemPlusVowel+"mos"; // same as present!?
            "2": result := ChangedStem+case Declination of
                    Declination.A: "asteis";
                    Declination.E: "isteis";
                    Declination.I: "isteis";
                  end;
            "3": result := ChangedStem+case Declination of
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
    //
    //
    //

    method getSubjuntivo(aSplit: List<String>): String;
    begin
      if aSplit.Count ≥ 0 then begin
        result := case aSplit[0] of
          "Present": getSubjuntivoPresent(aSplit.Skip(1).ToList);
          "Imperfect": getSubjuntivo1Imperfect(aSplit.Skip(1).ToList); // we only use Subjuntivo 1, for now
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