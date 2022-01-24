;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(uiop:define-package :nyxt/irc-mode
  (:use :common-lisp :nyxt)
  (:export :irc-mode)
  (:documentation "An IRC client within Nyxt."))

(in-package :nyxt/irc-mode)

(define-mode irc-mode ()
  "Launches an IRC client in a new buffer."
  ((rememberable-p nil)
   (keymap-scheme
    (define-scheme "irc"
      scheme:cua (list "return" 'send-command)
      scheme:emacs (list)))
   (style (theme:themed-css (theme *browser*)
            (* :font-family "monospace,monospace")
            (body :margin-right "0")
            ("#container" :display "flex"
                          :flex-flow "column"
                          :height "100%"
                          :color theme:text
                          :background-color theme:background)
            ("#input" :display "grid"
                      :grid-template-columns "auto 1fr"
                      :width "100%"
                      :padding 0
                      :margin 0
                      :background-color theme:tertiary)
            ("#input-buffer" :width "100%"
                             :border "none"
                             :outline "none"
                             :padding "3px"
                             :background-color theme:quaternary
                             :autofocus "true")
            ("#chat-history"
             :font-size "12px"
             :flex-grow "1"
             :overflow-y "auto"
             :overflow-x "auto")
            ("#prompt" :padding-right "4px"
                       :padding-left "4px"
                       :line-height "30px"
                       :color theme:background)
            (ul :list-style "none"
                :padding "0"
                :margin "0")
            (li :padding "2px"))
          :documentation "The CSS applied to the IRC client when set up.")))

(define-internal-page-command irc-client ()
    (irc-buffer "*IRC Client*" 'irc-mode)
  "Launch an IRC client."
  (spinneret:with-html-string
    (:head (:style (style (find-mode irc-buffer 'irc-mode))))
    (:body
     (:div :id "container"
           (:div :id "chat-history" "")
           (:div :id "input"
                 (:span :id "prompt"
                        (format nil ">"))
                 (:input :type "text" :id "input-buffer"))))))
