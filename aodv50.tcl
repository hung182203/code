# AODV Routing Protocol Simulation
# Mô phỏng mạng MANET với 50 nút

# Cấu hình mạng không dây
set val(chan) Channel/WirelessChannel     ;# Loại kênh
set val(prop) Propagation/TwoRayGround    ;# Mô hình lan truyền
set val(ant) Antenna/OmniAntenna          ;# Loại anten
set val(ll) LL                            ;# Lớp liên kết
set val(ifq) Queue/DropTail/PriQueue      ;# Loại hàng đợi
set val(ifqlen) 50                        ;# Độ dài tối đa hàng đợi
set val(netif) Phy/WirelessPhy            ;# Loại giao diện mạng
set val(mac) Mac/802_11                   ;# Loại MAC
set val(rp) AODV                          ;# Giao thức định tuyến
set val(nn) 50                            ;# Số lượng nút
set val(x) 1000                           ;# Chiều rộng địa hình
set val(y) 1000                           ;# Chiều cao địa hình

# Tạo đối tượng Simulator
set ns [new Simulator]

# Thiết lập truy vết
set tracefd [open aodv_simulation.tr w]
set namtrace [open aodv_simulation.nam w]

# Sử dụng truy vết mới
$ns use-newtrace
$ns trace-all $tracefd
$ns namtrace-all-wireless $namtrace $val(x) $val(y)

# Tạo địa hình
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

# Tạo God (Global Oracle of Destiny) để quản lý mạng không dây
create-god $val(nn)

# Tạo kênh không dây
set chan [new $val(chan)]

# Cấu hình nút
$ns node-config -adhocRouting $val(rp) \
                -llType $val(ll) \
                -macType $val(mac) \
                -ifqType $val(ifq) \
                -ifqLen $val(ifqlen) \
                -antType $val(ant) \
                -propType $val(prop) \
                -phyType $val(netif) \
                -channelType $val(chan) \
                -topoInstance $topo \
                -agentTrace ON \
                -routerTrace ON \
                -macTrace ON \
                -movementTrace ON \
                -channel $chan

# Tạo các nút
for {set i 0} {$i < $val(nn)} {incr i} {
    set node($i) [$ns node]
    $node($i) random-motion 0
}

# Đặt vị trí ban đầu cho các nút
for {set i 0} {$i < $val(nn)} {incr i} {
    $node($i) set X_ [expr rand() * $val(x)]
    $node($i) set Y_ [expr rand() * $val(y)]
    $node($i) set Z_ 0.0
}

# Định nghĩa mô hình di chuyển
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns at 0.0 "$node($i) setdest [expr rand()*$val(x)] [expr rand()*$val(y)] [expr 10+rand()*20]"
}

# Tạo các luồng lưu lượng
# Luồng CBR từ nút nguồn tới nút đích
set src_node $node(0)
set dst_node $node([expr $val(nn)-1])

# Tạo sink (điểm nhận)
set sink [new Agent/LossMonitor]
$ns attach-agent $dst_node $sink

# Tạo nguồn CBR
set cbr [new Agent/CBR]
$cbr set packetSize_ 512
$cbr set interval_ 0.25
$ns attach-agent $src_node $cbr
$ns connect $cbr $sink

# Lập lịch cho các sự kiện
$ns at 0.0 "$cbr start"
$ns at 30.0 "$cbr stop"

# Hàm kết thúc mô phỏng
proc finish {} {
    global ns tracefd namtrace
    $ns flush-trace
    close $tracefd
    close $namtrace
    
    # Chạy Nam để trực quan hóa (không bắt buộc)
    exec nam aodv_simulation.nam &
    exit 0
}

# Đặt sự kiện kết thúc
$ns at 31.0 "finish"

# Thiết lập seed ngẫu nhiên (tùy chọn)
ns-random 0

# Chạy mô phỏng
puts "Bắt đầu mô phỏng AODV..."
$ns run
