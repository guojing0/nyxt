;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(uiop:define-package :nyxt/irc-mode
  (:use :common-lisp :nyxt)
  (:export :irc-mode)
  (:documentation "An IRC client within Nyxt."))

(in-package :nyxt/irc-mode)

(define-mode irc-mode ()
  "Launches an IRC client in a new buffer."
  )
