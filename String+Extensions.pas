namespace Verbs;

type
  String_Extensions = public extension class(String)
  public

    property Last: Char read Chars[Length-1];

    method AddAccentToLastChar: String;
    begin
      result := self;
      if Length > 0 then
        result := Substring(0, Length-1)+self[Length-1].AddAccent;
    end;

  end;

  Char_Extensions = public extension class(Char)
  public

    method AddAccent: Char;
    begin
      result := case self of
        'a': 'á';
        'e': 'é';
        'i': 'í';
        'o': 'ó';
        'u': 'ú';
        else self;
      end;
    end;

  end;

end.