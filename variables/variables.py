from RPA.Robocorp.Vault import Vault

_secret = Vault().get_secret("secrets")

MODAL_BUTTON = _secret["modal-button"]
