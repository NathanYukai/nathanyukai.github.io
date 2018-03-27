module App exposing (..)

import Html exposing (..)
import Http
import Json.Decode as Decode
import View exposing (..)


init : String -> ( Model, Cmd Msg )
init topic =
    ( { topic = topic
      , gifs = []
      , waitingUrl = ""
      , inMerging = False
      }
    , getWaitingGif
    )



-- UPDATE


replaceIdx : List a -> Int -> a -> List a
replaceIdx lst idx e =
    List.take idx lst
        ++ [ e ]
        ++ List.drop (idx + 1) lst


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        replacedWithWaiting i =
            replaceIdx model.gifs
                i
                { url = model.waitingUrl
                , topic = ""
                , selected = False
                }

        replacedWithChanged i url =
            replaceIdx model.gifs i url
    in
    case msg of
        GetNewGif ->
            ( { model
                | gifs =
                    { url = model.waitingUrl
                    , topic = ""
                    , selected = False
                    }
                        :: model.gifs
              }
            , getRandomGif model.topic (ReceiveNewGif model.topic)
            )

        ChangeGif i ->
            ( { model | gifs = replacedWithWaiting i }
            , getRandomGif model.topic (ReceiveChangeGif i model.topic)
            )

        GetWaitingGif ->
            ( model, getWaitingGif )

        ReceiveNewGif tpc (Ok newUrl) ->
            ( { model
                | gifs =
                    addNewGifToList
                        { url = newUrl
                        , topic = tpc
                        , selected = False
                        }
                        model.gifs
              }
            , Cmd.none
            )

        ReceiveChangeGif idx tpc (Ok newUrl) ->
            ( { model
                | gifs =
                    replacedWithChanged idx
                        { url = newUrl
                        , topic = tpc
                        , selected = False
                        }
              }
            , Cmd.none
            )

        ReceiveWaitingGif (Ok newUrl) ->
            ( { model | waitingUrl = newUrl }
            , Cmd.none
            )

        ReceiveNewGif _ (Err _) ->
            ( model, Cmd.none )

        ReceiveWaitingGif (Err _) ->
            ( model, Cmd.none )

        ReceiveChangeGif _ _ (Err _) ->
            ( model, Cmd.none )

        ChangeTopic str ->
            ( { model | topic = str }, Cmd.none )

        ToggleMerge ->
            ( model, Cmd.none )

        ToggleGifSelect idx ->


getRandomGif : String -> (Result.Result Http.Error String -> Msg) -> Cmd Msg
getRandomGif topic msg =
    let
        url =
            giphyUrl
                ++ "random?"
                ++ apiKey
                ++ "&tag="
                ++ topic
    in
    Http.send msg (Http.get url decodeGifs)


addNewGifToList : a -> List a -> List a
addNewGifToList s lst =
    case lst of
        [] ->
            []

        l :: rest ->
            s :: rest


getWaitingGif : Cmd Msg
getWaitingGif =
    let
        url =
            waitingUrl
    in
    Http.send ReceiveWaitingGif (Http.get url decodeGifs)


giphyUrl : String
giphyUrl =
    "https://api.giphy.com/v1/gifs/"


apiKey : String
apiKey =
    "api_key=LhH2kxvrnOiFtgADwGFwI3LwhiEzfab8"


waitingUrl : String
waitingUrl =
    giphyUrl
        ++ "random?"
        ++ apiKey
        ++ "&tag="
        ++ "waiting"


decodeGifs : Decode.Decoder String
decodeGifs =
    Decode.at
        [ "data"
        , "images"
        , "fixed_height"
        , "url"
        ]
        Decode.string



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- MAIN


main : Program Never Model Msg
main =
    program
        { init = init "cat"
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
