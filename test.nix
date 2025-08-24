let
  original = [ 1 2 3 ];
  transformed = map (n: "asdf${toString n}") original;
in transformed

