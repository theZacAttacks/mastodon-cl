(in-package :mastodon.api)

(defun get-blocks (&key max-id since-id (limit 40))
  (setq limit (min limit 80))
  (decode-json-from-string
   (masto--perform-request `(:get
			    ,(concatenate 'string
					  "blocks"
					  "?limit=" (write-to-string limit)
					  (if max-id (concatenate 'string "&max_id=" max-id))
					  (if since-id (concatenate 'string "&since_id=" since-id)))))))

(defun get-domain-blocks (&key max-id since-id (limit 40))
  (setq limit (min limit 80))
  (decode-json-from-string
   (masto--perform-request `(:get
			    ,(concatenate 'string
					  "domain_blocks"
					  "?limit=" (write-to-string limit)
					  (if max-id (concatenate 'string "&max_id=" max-id))
					  (if since-id (concatenate 'string "&since_id=" since-id)))))))

(defun block-domain (domain)
  (masto--perform-request `(:post 
			   ,(concatenate 'string
					 "domain_blocks"
					 "?domain=" domain))))

(defun unblock-domain (domain)
  (masto--perform-request `(:delete
			   ,(concatenate 'string
					 "domain_blocks"
					 "?domain=" domain))))

(defun block-account (id)
  (masto--perform-request `(:post
			   ,(concatenate 'string
					 "accounts/" id "/block"))))

(defun unblock-account (id)
  (masto--perform-request `(:post
			   ,(concatenate 'string
					 "accounts/" id "/unblock"))))

(defun mute-account (id)
  (masto--perform-request `(:post
			   ,(concatenate 'string
					 "accounts/" id "/mute"))))

(defun unmute-account (id)
  (masto--perform-request `(:post
			   ,(concatenate 'string
					 "accounts/" id "/unmute"))))

(defun get-mutes (&key max-id since-id (limit 40))
  (setq limit (min limit 80))
  (decode-json-from-string
   (masto--perform-request `(:get
			    ,(concatenate 'string
					  "mutes"
					  "?limit=" (write-to-string limit)
					  (if max-id (concatenate 'string "&max_id=" max-id))
					  (if since-id (concatenate 'string "&since_id=" since-id)))))))
