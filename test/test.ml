(***************************************************************************)
(*  Copyright (c) 2022 Dhruv Makwana                                       *)
(*  All rights reserved.                                                   *)
(*                                                                         *)
(*  This software was developed by the University of Cambridge Computer    *)
(*  Laboratory as part of the Rigorous Engineering of Mainstream Systems   *)
(*  (REMS) project. This project has been partly funded by an EPSRC        *)
(*  Doctoral Training studentship. This project has been partly funded by  *)
(*  Google. This project has received funding from the European Research   *)
(*  Council (ERC) under the European Union's Horizon 2020 research and     *)
(*  innovation programme (grant agreement No 789108, Advanced Grant        *)
(*  ELVER).                                                                *)
(*                                                                         *)
(*  BSD 2-Clause License                                                   *)
(*                                                                         *)
(*  Redistribution and use in source and binary forms, with or without     *)
(*  modification, are permitted provided that the following conditions     *)
(*  are met:                                                               *)
(*  1. Redistributions of source code must retain the above copyright      *)
(*     notice, this list of conditions and the following disclaimer.       *)
(*  2. Redistributions in binary form must reproduce the above copyright   *)
(*     notice, this list of conditions and the following disclaimer in     *)
(*     the documentation and/or other materials provided with the          *)
(*     distribution.                                                       *)
(*                                                                         *)
(*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''     *)
(*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED      *)
(*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A        *)
(*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR    *)
(*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,           *)
(*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       *)
(*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF       *)
(*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND    *)
(*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,     *)
(*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT     *)
(*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF     *)
(*  SUCH DAMAGE.                                                           *)
(***************************************************************************)

module Cs = Comment_simplifier

let ignor = "//-"
let esc_nl = "\\\n"
let line_start = [ ignor; "line_start" ]
let kept_line = [ esc_nl; "\n"; "//"; "/*"; "\""; "kept_line" ]
let kept_block_comment = [ "\n" ^ ignor; "\n"; "*/"; "kept_block_comment" ]
let kept_str = [ esc_nl; "\\\\"; "\\\""; "\""; "\n"; "kept_str" ]
let ignored_line = [ esc_nl ^ ignor; esc_nl; "\n"; "/*"; "//"; "ignored_line" ]
let commented_line = [ esc_nl ^ ignor; esc_nl; "\n"; "commented_line" ]

let ignored_block_comment =
  [ esc_nl ^ ignor; esc_nl; "\n"; "*/"; ignor; "ignored_block_comment" ]

let empty_line = [ esc_nl; "//"; "\n"; "/*"; "empty_line" ]

let test_string str =
  match Cs.from_string str with
  | Result.Ok () -> ()
  | Result.Error (reason, pos) ->
    Printf.printf "%s: string:%d:%d" (Cs.Lexer.show_err reason) pos.pos_lnum pos.pos_cnum

let test_all tests =
  List.iter
    (fun x ->
      print_string x;
      print_string "\n-->\n";
      test_string x;
      print_string "\n====\n")
    tests

let test_with prefix tests =
  test_all @@ List.map (fun x -> String.concat " " (prefix @ [ x ])) tests

let%expect_test "line_start -> _" =
  test_all line_start;
  [%expect
    {|
    //-
    -->

    ====
    line_start
    -->
    line_start
    ==== |}]

let%expect_test "line_start -> kept_line -> _" =
  test_with [ "line_start" ] kept_line;
  [%expect
    {|
    line_start \

    -->
    line_start \

    ====
    line_start

    -->
    line_start

    ====
    line_start //
    -->
    line_start //
    ====
    line_start /*
    -->
    line_start /*Eof_in_comment
    ====
    line_start "
    -->
    line_start "Eof_in_string
    ====
    line_start kept_line
    -->
    line_start kept_line
    ==== |}]

let%expect_test "line_start -> kept_line -> kept_line" =
  test_with [ "line_start"; esc_nl ] kept_line;
  [%expect
    {|
    line_start \
     \

    -->
    line_start \
     \

    ====
    line_start \


    -->
    line_start \


    ====
    line_start \
     //
    -->
    line_start \
     //
    ====
    line_start \
     /*
    -->
    line_start \
     /*Eof_in_comment
    ====
    line_start \
     "
    -->
    line_start \
     "Eof_in_string
    ====
    line_start \
     kept_line
    -->
    line_start \
     kept_line
    ==== |}]

let%expect_test "line_start -> kept_line -> line_start" =
  test_with [ "line_start"; "\n" ] line_start;
  [%expect
    {|
    line_start
     //-
    -->
    line_start
     //-
    ====
    line_start
     line_start
    -->
    line_start
     line_start
    ==== |}]

let%expect_test "line_start -> kept_line -> commented_line" =
  test_with [ "line_start"; "//" ] commented_line;
  [%expect
    {|
    line_start // \
    //-
    -->
    line_start // \

    ====
    line_start // \

    -->
    line_start // \

    ====
    line_start //

    -->
    line_start //

    ====
    line_start // commented_line
    -->
    line_start // commented_line
    ==== |}]

let%expect_test "line_start -> kept_line -> commented_line" =
  test_with [ "line_start"; "//"; esc_nl ^ ignor ] commented_line;
  [%expect
    {|
    line_start // \
    //- \
    //-
    -->
    line_start // \
     \

    ====
    line_start // \
    //- \

    -->
    line_start // \
     \

    ====
    line_start // \
    //-

    -->
    line_start // \


    ====
    line_start // \
    //- commented_line
    -->
    line_start // \
     commented_line
    ==== |}]

let%expect_test "line_start -> kept_line -> commented_line -> line_start" =
  test_with [ "line_start"; "//"; "\n" ] line_start;
  [%expect
    {|
    line_start //
     //-
    -->
    line_start //
     //-
    ====
    line_start //
     line_start
    -->
    line_start //
     line_start
    ==== |}]

let%expect_test "line_start -> kept_line -> commented_line -> commented_line" =
  test_with [ "line_start"; "//"; "commented_line" ] commented_line;
  [%expect
    {|
    line_start // commented_line \
    //-
    -->
    line_start // commented_line \

    ====
    line_start // commented_line \

    -->
    line_start // commented_line \

    ====
    line_start // commented_line

    -->
    line_start // commented_line

    ====
    line_start // commented_line commented_line
    -->
    line_start // commented_line commented_line
    ==== |}]

let%expect_test "line_start -> kept_line -> kept_block_comment" =
  test_with [ "line_start"; "/*" ] kept_block_comment;
  [%expect
    {|
    line_start /*
    //-
    -->
    line_start /*
    Eof_in_comment
    ====
    line_start /*

    -->
    line_start /*
    Eof_in_comment
    ====
    line_start /* */
    -->
    line_start /* */
    ====
    line_start /* kept_block_comment
    -->
    line_start /* kept_block_commentEof_in_comment
    ==== |}]

let%expect_test "line_start -> kept_line -> kept_block_comment -> \
                 kept_block_comment" =
  test_with [ "line_start"; "/*"; "kept_block_comment" ] kept_block_comment;
  [%expect
    {|
    line_start /* kept_block_comment
    //-
    -->
    line_start /* kept_block_comment
    Eof_in_comment
    ====
    line_start /* kept_block_comment

    -->
    line_start /* kept_block_comment
    Eof_in_comment
    ====
    line_start /* kept_block_comment */
    -->
    line_start /* kept_block_comment */
    ====
    line_start /* kept_block_comment kept_block_comment
    -->
    line_start /* kept_block_comment kept_block_commentEof_in_comment
    ==== |}]

let%expect_test "line_start -> kept_line -> kept_block_comment -> kept_line" =
  test_with [ "line_start"; "/*"; "*/" ] kept_line;
  [%expect
    {|
    line_start /* */ \

    -->
    line_start /* */ \

    ====
    line_start /* */

    -->
    line_start /* */

    ====
    line_start /* */ //
    -->
    line_start /* */ //
    ====
    line_start /* */ /*
    -->
    line_start /* */ /*Eof_in_comment
    ====
    line_start /* */ "
    -->
    line_start /* */ "Eof_in_string
    ====
    line_start /* */ kept_line
    -->
    line_start /* */ kept_line
    ==== |}]

let%expect_test "line_start -> kept_line -> kept_string" =
  test_with [ "line_start"; "\"" ] kept_str;
  [%expect
    {|
    line_start " \

    -->
    line_start " \
    Eof_in_string
    ====
    line_start " \\
    -->
    line_start " \\Eof_in_string
    ====
    line_start " \"
    -->
    line_start " \"Eof_in_string
    ====
    line_start " "
    -->
    line_start " "
    ====
    line_start "

    -->
    line_start " Newline_in_string
    ====
    line_start " kept_str
    -->
    line_start " kept_strEof_in_string
    ==== |}]

let%expect_test "line_start -> kept_line -> kept_string -> kept_line" =
  test_with [ "line_start"; "\""; "\"" ] kept_line;
  [%expect
    {|
    line_start " " \

    -->
    line_start " " \

    ====
    line_start " "

    -->
    line_start " "

    ====
    line_start " " //
    -->
    line_start " " //
    ====
    line_start " " /*
    -->
    line_start " " /*Eof_in_comment
    ====
    line_start " " "
    -->
    line_start " " "Eof_in_string
    ====
    line_start " " kept_line
    -->
    line_start " " kept_line
    ==== |}]

let%expect_test "line_start -> kept_line -> kept_line" =
  test_with [ "line_start"; "kept_line" ] kept_line;
  [%expect
    {|
    line_start kept_line \

    -->
    line_start kept_line \

    ====
    line_start kept_line

    -->
    line_start kept_line

    ====
    line_start kept_line //
    -->
    line_start kept_line //
    ====
    line_start kept_line /*
    -->
    line_start kept_line /*Eof_in_comment
    ====
    line_start kept_line "
    -->
    line_start kept_line "Eof_in_string
    ====
    line_start kept_line kept_line
    -->
    line_start kept_line kept_line
    ==== |}]

let%expect_test "line_start -> ignored_line" =
  test_with [ ignor ] ignored_line;
  [%expect
    {|
    //- \
    //-
    -->
    //- \

    ====
    //- \

    -->
    //- \

    ====
    //-

    -->


    ====
    //- /*
    -->
    Eof_in_comment
    ====
    //- //
    -->
     //
    ====
    //- ignored_line
    -->
    //- ignored_line
    ==== |}]

let%expect_test "line_start -> ignored_line -> commented_line" =
  test_with [ ignor; "//" ] commented_line;
  [%expect
    {|
    //- // \
    //-
    -->
     // \

    ====
    //- // \

    -->
     // \

    ====
    //- //

    -->
     //

    ====
    //- // commented_line
    -->
     // commented_line
    ==== |}]

let%expect_test "line_start -> ignored_line -> line_start" =
  test_with [ ignor; "\n" ] line_start;
  [%expect
    {|
    //-
     //-
    -->

     //-
    ====
    //-
     line_start
    -->

     line_start
    ==== |}]

let%expect_test "line_start -> ignored_line -> ignored_block_comment" =
  test_with [ ignor; "/*" ] ignored_block_comment;
  [%expect
    {|
    //- /* \
    //-
    -->
    Eof_in_comment
    ====
    //- /* \

    -->
    Eof_in_comment
    ====
    //- /*

    -->
    Eof_in_comment
    ====
    //- /* */
    -->
     /* */
    ====
    //- /* //-
    -->
    Eof_in_comment
    ====
    //- /* ignored_block_comment
    -->
    Eof_in_comment
    ==== |}]

let%expect_test "line_start -> ignored_line -> ignored_block_comment -> \
                 ignored_block_comment" =
  test_with [ ignor; "/*"; esc_nl ^ ignor ] ignored_block_comment;
  [%expect
    {|
    //- /* \
    //- \
    //-
    -->
    Eof_in_comment
    ====
    //- /* \
    //- \

    -->
    Eof_in_comment
    ====
    //- /* \
    //-

    -->
    Eof_in_comment
    ====
    //- /* \
    //- */
    -->
     /* \
     */
    ====
    //- /* \
    //- //-
    -->
    Eof_in_comment
    ====
    //- /* \
    //- ignored_block_comment
    -->
    Eof_in_comment
    ==== |}]

let%expect_test "line_start -> ignored_line -> ignored_block_comment -> \
                 ignored_line" =
  test_with [ ignor; "/*"; "*/" ] ignored_line;
  [%expect
    {|
    //- /* */ \
    //-
    -->
    //- /* */ \

    ====
    //- /* */ \

    -->
    //- /* */ \

    ====
    //- /* */

    -->
     /* */

    ====
    //- /* */ /*
    -->
    Eof_in_comment
    ====
    //- /* */ //
    -->
     /* */ //
    ====
    //- /* */ ignored_line
    -->
    //- /* */ ignored_line
    ==== |}]

let%expect_test "line_start -> ignored_line -> ignored_block_comment -> \
                 ignored_block_comment -> empty_line" =
  test_with [ ignor; "/*"; "\n*/" ] empty_line;
  [%expect
    {|
    //- /*
    */ \

    -->
     /*
    */ \

    ====
    //- /*
    */ //
    -->
     /*
    */ //
    ====
    //- /*
    */

    -->
     /*
    */

    ====
    //- /*
    */ /*
    -->
     /*
    */ /*Eof_in_comment
    ====
    //- /*
    */ empty_line
    -->
     /*
    */ No_code_after_multi_line_block_comment
    ==== |}]
