import pyotp
import sys
secret = sys.argv[1]
totp = pyotp.TOTP(secret)
otp = totp.now()
print(otp)