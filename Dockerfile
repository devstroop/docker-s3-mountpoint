# Download and verify the RPM in this container
FROM public.ecr.aws/amazonlinux/amazonlinux:2023 as builder

# Install necessary tools
RUN dnf install -y --allowerasing wget gnupg2

RUN MP_ARCH=`uname -p | sed s/aarch64/arm64/` && \
    wget -q "https://s3.amazonaws.com/mountpoint-s3-release/latest/$MP_ARCH/mount-s3.rpm" && \
    wget -q "https://s3.amazonaws.com/mountpoint-s3-release/latest/$MP_ARCH/mount-s3.rpm.asc" && \
    wget -q https://s3.amazonaws.com/mountpoint-s3-release/public_keys/KEYS

# Import the key and validate it
RUN gpg --import KEYS && \
    (gpg --fingerprint mountpoint-s3@amazon.com | grep "673F E406 1506 BB46 9A0E  F857 BE39 7A52 B086 DA5A")

# Verify the binary
RUN gpg --verify mount-s3.rpm.asc

# Install the RPM in a fresh container
FROM amazonlinux:2023
COPY --from=builder /mount-s3.rpm /mount-s3.rpm

RUN dnf upgrade -y && \
    dnf install -y ./mount-s3.rpm && \
    dnf clean all && \
    rm mount-s3.rpm

# Allow FUSE for all users
RUN echo "user_allow_other" >> /etc/fuse.conf

# Set the entrypoint to the script
ENTRYPOINT [ "mount-s3", "-f" ]

