  ;disable backup
  (setq backup-inhibited t)
  ;disable auto save
  (setq auto-save-default nil)
  ; 80 character highlighting
  (require 'whitespace)
  (setq whitespace-line-column 80) ;; limit line length
  (setq whitespace-style '(face lines-tail))
  (add-hook 'prog-mode-hook 'whitespace-mode)
