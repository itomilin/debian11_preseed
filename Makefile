master-kvm-gen-preseed-file:
	./generate_preseed.sh \
	nointeractive \
	master-kvm \
	pass \
	master \
	pass \
	192.168.10 \
	100

worker1-kvm-gen-preseed-file:
	./generate_preseed.sh \
	nointeractive \
	worker1-kvm \
	pass \
	worker1 \
	pass \
	192.168.10 \
	101

worker2-kvm-gen-preseed-file:
	./generate_preseed.sh \
	nointeractive \
	worker2-kvm \
	pass \
	worker2 \
	pass \
	192.168.10 \
	102

all: master-kvm-gen-preseed-file \
	 worker1-kvm-gen-preseed-file \
	 worker2-kvm-gen-preseed-file
