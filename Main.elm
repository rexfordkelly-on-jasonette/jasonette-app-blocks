port module Main exposing (..)

import Focus
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode


port newJason : String -> Cmd msg


type alias Model =
    { head : HeadOptions
    , body : Body
    }


type alias HeadOptions =
    { title : String }


type alias Body =
    { header : Header
    , sections : List Section
    }


type alias Section =
    { type_ : BodySectionType
    , items : List BodySectionItem
    }


type BodySectionType
    = Horizontal
    | Vertical


type BodySectionItem
    = Component ComponentDetail


type ComponentDetail
    = LabelType
        { text : String
        }


type Title
    = SimpleTitle String
    | LabelTitle { text : String }
    | ImageTitle { url : String }


type alias Header =
    { title : Title
    , style : Maybe Style
    }


type alias Style =
    { font : String
    , size : String
    , background : String
    , color : String
    }


type Msg
    = NoOp
    | UpdateHead (HeadOptions -> HeadOptions)
    | UpdateBodyHeader (Header -> Header)
    | AddBodySection
    | SetSectionType Int BodySectionType
    | UpdateComponent Int Int (ComponentDetail -> ComponentDetail)
    | AddComponent Int


main =
    Html.program
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }


initialModel : Model
initialModel =
    { head =
        { title = "Your Title"
        }
    , body =
        { header =
            { title = SimpleTitle "Your Title"
            , style =
                Nothing
            }
        , sections =
            [ Section Vertical
                []
            ]
        }
    }


init : ( Model, Cmd Msg )
init =
    initialModel |> renderHtml


renderHtml : Model -> ( Model, Cmd Msg )
renderHtml model =
    ( model
    , encodeJson model
        |> Json.Encode.encode 0
        |> newJason
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UpdateHead headFn ->
            ( { model | head = headFn model.head }, Cmd.none )

        UpdateBodyHeader headFn ->
            let
                body =
                    model.body

                header =
                    model.body.header
            in
            { model
                | body =
                    { body
                        | header = headFn header
                    }
            }
                |> renderHtml

        AddBodySection ->
            let
                body =
                    model.body

                sections =
                    model.body.sections
            in
            { model
                | body =
                    { body
                        | sections = sections ++ [ Section Vertical [ Component <| LabelType { text = "New Label" } ] ]
                    }
            }
                |> renderHtml

        SetSectionType id sectionType ->
            let
                body =
                    model.body

                sections =
                    model.body.sections
            in
            { model
                | body =
                    { body
                        | sections =
                            List.indexedMap
                                (\i ->
                                    \v ->
                                        if i == id then
                                            { v | type_ = sectionType }
                                        else
                                            v
                                )
                                sections
                    }
            }
                |> renderHtml

        AddComponent id ->
            let
                body =
                    model.body

                sections =
                    model.body.sections
            in
            { model
                | body =
                    { body
                        | sections =
                            List.indexedMap
                                (\i ->
                                    \v ->
                                        if i == id then
                                            { v | items = v.items ++ [ Component <| LabelType { text = "Label" } ] }
                                        else
                                            v
                                )
                                sections
                    }
            }
                |> renderHtml

        UpdateComponent sectionId itemId componentFn ->
            let
                body =
                    model.body

                sections =
                    model.body.sections
            in
            { model
                | body =
                    { body
                        | sections =
                            List.indexedMap
                                (\i ->
                                    \v ->
                                        if i == sectionId then
                                            let
                                                items =
                                                    v.items
                                            in
                                            { v
                                                | items =
                                                    List.indexedMap
                                                        (\j ->
                                                            \item ->
                                                                if j == itemId then
                                                                    case item of
                                                                        Component componentDetail ->
                                                                            Component (componentFn componentDetail)
                                                                else
                                                                    item
                                                        )
                                                        items
                                            }
                                        else
                                            v
                                )
                                sections
                    }
            }
                |> renderHtml


stylesheet =
    let
        tag =
            "link"

        attrs =
            [ attribute "rel" "stylesheet"
            , attribute "property" "stylesheet"
            , attribute "href" "https://fonts.googleapis.com/css?family=Roboto|Roboto+Mono"
            ]

        children =
            []
    in
    node tag attrs children


view : Model -> Html Msg
view model =
    div
        [ style
            [ ( "width", "100%" )
            , ( "display", "flex" )
            , ( "font-family", "'Roboto', sans-serif" )
            ]
        ]
        [ stylesheet
        , div
            [ style
                [ ( "width", "50%" )
                , ( "padding", "10px" )
                , ( "overflow-y", "scroll" )
                , ( "border-right", "1px dotted" )
                , ( "height", "calc(100vh - 20px)" )
                ]
            ]
            [ h1 [] [ text "Editor" ]
            , editor model
            ]
        , div
            [ style
                [ ( "width", "50%" )
                , ( "height", "100vh" )
                , ( "border-right", "1px dotted" )
                , ( "padding", "10px" )
                , ( "overflow-y", "scroll" )
                , ( "height", "calc(100vh - 20px)" )
                ]
            ]
            [ h1 [] [ text "Output" ]
            , pre
                [ style
                    [ ( "font-family", "'Roboto Mono', monospace" )
                    ]
                ]
                [ encodeJson model
                    |> Json.Encode.encode 2
                    |> text
                ]
            ]
        ]


editor : Model -> Html Msg
editor model =
    div []
        ([ h2 [] [ text "Head" ]
         , stringInput "Title"
            model.head.title
            (\str -> UpdateHead (\head -> { head | title = str }))
         , hr [] []
         , h2 [] [ text "Body" ]
         , h3 [] [ text "Header" ]
         , dropdownInput "header-style"
            (case model.body.header.style of
                Nothing ->
                    "Unstyled Header"

                Just _ ->
                    "Styled Header"
            )
            [ "Unstyled Header", "Styled Header" ]
            (\str ->
                case str of
                    "Styled Header" ->
                        UpdateBodyHeader
                            (\header ->
                                { header
                                    | style =
                                        Just
                                            { font = "Avenir-Black"
                                            , size = "20"
                                            , background = "#27aae1"
                                            , color = "#ffffff"
                                            }
                                }
                            )

                    _ ->
                        UpdateBodyHeader
                            (\header ->
                                { header
                                    | style =
                                        Nothing
                                }
                            )
            )
         , case model.body.header.style of
            Nothing ->
                text ""

            Just style ->
                styleEditor style
         , dropdownInput "title-type"
            (case model.body.header.title of
                SimpleTitle _ ->
                    "Simple Title"

                LabelTitle _ ->
                    "Label Title"

                ImageTitle _ ->
                    "Image Title"
            )
            [ "Simple Title", "Label Title", "Image Title" ]
            (\str ->
                case str of
                    "Image Title" ->
                        UpdateBodyHeader (\header -> { header | title = ImageTitle { url = "http://via.placeholder.com/350x150" } })

                    "Label Title" ->
                        UpdateBodyHeader (\header -> { header | title = LabelTitle { text = "" } })

                    _ ->
                        UpdateBodyHeader (\header -> { header | title = SimpleTitle "" })
            )
         , case model.body.header.title of
            SimpleTitle str ->
                stringInput "Simple Title"
                    str
                    (\str -> UpdateBodyHeader (\header -> { header | title = SimpleTitle str }))

            LabelTitle t ->
                stringInput "Label Title"
                    t.text
                    (\str -> UpdateBodyHeader (\header -> { header | title = LabelTitle { text = str } }))

            ImageTitle t ->
                stringInput "Image Title"
                    t.url
                    (\str -> UpdateBodyHeader (\header -> { header | title = ImageTitle { url = str } }))
         , hr [] []
         , h3 [] [ text "Sections" ]
         ]
            ++ List.indexedMap
                (\sectionNum ->
                    \section ->
                        div []
                            [ dropdownInput ("section-type-" ++ toString sectionNum) section.type_ [ Vertical, Horizontal ] (SetSectionType sectionNum)
                            , div []
                                (List.indexedMap
                                    (\itemNum ->
                                        \item ->
                                            case item of
                                                Component componentDetail ->
                                                    case componentDetail of
                                                        LabelType label ->
                                                            stringInput "Label Text" label.text (\str -> UpdateComponent sectionNum itemNum (\_ -> LabelType { text = str }))
                                    )
                                    section.items
                                )
                            , btn "Add Component" (AddComponent sectionNum)
                            , hr [] []
                            ]
                )
                model.body.sections
            ++ [ btn "Add Section" AddBodySection ]
        )


btn : String -> Msg -> Html Msg
btn str msg =
    button
        [ onClick msg
        , style
            [ ( "font-family", "'Roboto Mono', monospace" )
            , ( "background-color", "lightgreen" )
            , ( "color", "darkblue" )
            , ( "border-radius", "5px" )
            , ( "padding", "2px" )
            , ( "font-size", "15px" )
            ]
        ]
        [ text str ]


styleEditor : Style -> Html Msg
styleEditor style =
    span []
        [ colorInput "Background"
            style.background
            (\str ->
                UpdateBodyHeader
                    (\header ->
                        { header
                            | style =
                                Maybe.map (\headerStyle -> { headerStyle | background = str }) header.style
                        }
                    )
            )
        , colorInput "Foreground"
            style.color
            (\str ->
                UpdateBodyHeader
                    (\header ->
                        { header
                            | style =
                                Maybe.map (\headerStyle -> { headerStyle | color = str }) header.style
                        }
                    )
            )
        ]


colorInput : String -> String -> (String -> Msg) -> Html Msg
colorInput name selectedColor colorMsg =
    span []
        [ label [] [ text name ]
        , input
            [ type_ "color"
            , value selectedColor
            , onInput colorMsg
            ]
            []
        ]


dropdownInput : String -> a -> List a -> (a -> Msg) -> Html Msg
dropdownInput inputName selectedValue options optionFn =
    fieldset []
        (List.map
            (\x ->
                label []
                    [ input
                        [ type_ "radio"
                        , name inputName
                        , onClick (optionFn x)
                        , checked (selectedValue == x)
                        ]
                        []
                    , text (toString x)
                    ]
            )
            options
        )


stringInput : String -> String -> (String -> Msg) -> Html Msg
stringInput inputName str updateFn =
    span []
        [ label [] [ text inputName ]
        , br [] []
        , input
            [ type_ "text"
            , value str
            , style
                [ ( "font-family", "'Roboto', sans-serif" )
                , ( "font-size", "20px" )
                , ( "border-radius", "5px" )
                , ( "border-style", "groove" )
                , ( "width", "100%" )
                ]
            , onInput (\str -> updateFn str)
            ]
            []
        ]


encodeStyle : Style -> Json.Encode.Value
encodeStyle style =
    Json.Encode.object
        [ ( "font", Json.Encode.string style.font )
        , ( "size", Json.Encode.string style.size )
        , ( "background", Json.Encode.string style.background )
        , ( "color", Json.Encode.string style.color )
        ]


encodeTitle : Title -> Json.Encode.Value
encodeTitle title =
    case title of
        SimpleTitle str ->
            Json.Encode.string str

        LabelTitle t ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "label" )
                , ( "text", Json.Encode.string t.text )
                ]

        ImageTitle t ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "image" )
                , ( "url", Json.Encode.string t.url )
                ]


encodeJson : Model -> Json.Encode.Value
encodeJson model =
    Json.Encode.object
        [ ( "$jason"
          , Json.Encode.object
                [ ( "head"
                  , Json.Encode.object
                        [ ( "title"
                          , Json.Encode.string model.head.title
                          )
                        ]
                  )
                , ( "body"
                  , Json.Encode.object
                        [ ( "header"
                          , Json.Encode.object
                                ([ ( "title", encodeTitle model.body.header.title ) ]
                                    ++ (case model.body.header.style of
                                            Nothing ->
                                                []

                                            Just style ->
                                                [ ( "style", encodeStyle style ) ]
                                       )
                                )
                          )
                        , ( "sections"
                          , Json.Encode.list <|
                                List.map
                                    (\section ->
                                        Json.Encode.object
                                            [ ( "type"
                                              , Json.Encode.string <|
                                                    case section.type_ of
                                                        Horizontal ->
                                                            "horizontal"

                                                        Vertical ->
                                                            "vertical"
                                              )
                                            , ( "items"
                                              , Json.Encode.list <|
                                                    List.map
                                                        (\item ->
                                                            Json.Encode.object <|
                                                                case item of
                                                                    Component component ->
                                                                        case component of
                                                                            LabelType label ->
                                                                                [ ( "type", Json.Encode.string "label" )
                                                                                , ( "text", Json.Encode.string label.text )
                                                                                ]
                                                        )
                                                        section.items
                                              )
                                            ]
                                    )
                                    model.body.sections
                          )
                        ]
                  )
                ]
          )
        ]
