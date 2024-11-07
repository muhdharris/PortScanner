require 'socket'
require 'terminal-table'

# Constants
TIMEOUT = 2
DEFAULT_PORTS = [21, 22, 23, 25, 53, 80, 443, 3306, 8080]

# Function to scan a single port
def scan_port(ip, port)
  socket = Socket.new(:INET, :STREAM)
  remote_addr = Socket.sockaddr_in(port, ip)

  # Try to connect to the port
  begin
    socket.connect_nonblock(remote_addr)
  rescue Errno::EINPROGRESS
    # Connection is in progress, handled by IO.select below
  rescue => e
    return { port: port, status: "Closed (Error: #{e.message})" }
  end

  _, sockets, _ = IO.select(nil, [socket], nil, TIMEOUT)
  socket.close

  if sockets
    { port: port, status: "Open" }
  else
    { port: port, status: "Closed" }
  end
end

# Function to scan a list of ports on a given IP address
def scan_ports(ip, ports)
  puts "Starting scan on #{ip} with a timeout of #{TIMEOUT} seconds per port..."

  results = []
  threads = []

  ports.each do |port|
    threads << Thread.new do
      results << scan_port(ip, port)
    end
  end

  threads.each(&:join)

  # Display results in a neatly formatted table
  rows = []
  results.each do |result|
    rows << [result[:port], result[:status]]
    rows << :separator  # Add a separator row between ports
  end

  # Remove the last separator to avoid an empty row at the end
  rows.pop if rows.last == :separator

  # Create the table
  table = Terminal::Table.new do |t|
    t.title = "Port Scan Results"
    t.headings = ['Port', 'Status']
    t.rows = rows
  end

  puts "\n#{table}\n"
  puts "Summary: #{results.count { |res| res[:status].include?('Open') }} open ports found."
end

# Allow user to input target and ports
puts "Enter the target IP or domain (e.g., 'google.com' or '192.168.1.1'):"
target_ip = gets.chomp

# Provide options for ports
puts "Select ports to scan (you can enter multiple numbers separated by commas):"
puts "1. Default common ports: #{DEFAULT_PORTS.join(', ')}"
puts "2. Custom ports (enter your own):"
print "Enter your choice (1 for default, 2 for custom): "
choice = gets.chomp.to_i

ports = []

if choice == 1
  ports = DEFAULT_PORTS
elsif choice == 2
  puts "Enter ports to scan, separated by commas (e.g., 21,22,80,443):"
  port_input = gets.chomp
  ports = port_input.split(',').map(&:to_i)
else
  puts "Invalid choice. Exiting."
  exit
end

# Run the scan
scan_ports(target_ip, ports)
