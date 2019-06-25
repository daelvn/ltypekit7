external val print : 'a -> unit = "print"

type maybe 'a =
  | Nothing
  | Just of 'a

let fromMaybe d x =
  match x with
  | Nothing -> d
  | Just n -> n

let () = print (fromMaybe "no string" (Just "is string"))
