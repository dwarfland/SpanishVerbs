namespace Verbs;

type
  String_Extensions = public extension class(String)
  public

    property Last: Char read Chars[Length-1];

  end;

end.