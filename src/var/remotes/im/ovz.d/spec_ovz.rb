#!/usr/bin/env ruby


# This class gathers interesting OpenVZ
# specific system information 
class IMOpenVZDriver

	@@vzcpucheck_cmd = "/usr/sbin/vzcpucheck"
	@@vzmemcheck_cmd = "sudo /usr/sbin/vzmemcheck"

	# Gathers information about openvz cpu units utilisation
	# cpu unit is a number calculated by OpenVZ with the help of the special algorithm 
	# Current CPU utilization (CURRENT_CPU_UTIL) show the total cpu current
	# utilisation (in units) assigned to currently running containers
	# and the host system processess 
	# Power of the node (NODE_CPU_POWER)) is a cpu power of all cpus available 
	# on the host mesured in the same units
	# if the CURRENT_CPU_UTIL < NODE_CPU_POWER it means that the node is under 
	# utilized and the containers can receive more cpu that they have guaranree 
	# to receive (if no cpu_limit for the containers is set) 
	# if CURRENT_CPU_UTIL > NODE_CPU_POWER, node is overcommited: the node promised 
	# more cpu units than the power of the Hardware Node. In this case, 
	# the containers might receive less power that they had been guaranted to receive
	# * *Returns* :
	# - current_cpu_utilization, node_cpu_power parameters of system as strings
	def self.print
		output = IO.popen(@@vzcpucheck_cmd )
		vzcpucheck_text= output.read
		current_cpu_utilization, node_cpu_power = IMOpenVZParser.parse_cpu_power(vzcpucheck_text)
	    	puts "CURRENT_CPU_UTIL=#{current_cpu_utilization}"
	    	puts "NODE_CPU_POWER=#{node_cpu_power}"

		output = IO.popen(@@vzmemcheck_cmd )
		vzmemcheck_text= output.read
		alloc_util, alloc_commit, alloc_limit = IMOpenVZParser.parse_memcheck(vzmemcheck_text)
	    	puts "MEMORY_ALLOC_UTIL=#{alloc_util}"
	    	puts "MEMORY_ALLOC_COMMIT=#{alloc_commit}"
	    	puts "MEMORY_ALLOC_LIMIT=#{alloc_limit}"
	end
end

# This class provides a convinien way of getting interesting OpenVZ
# specific system information 
class IMOpenVZParser

	# Parses vzcpucheck output to output current cpu utilisation of the node and
	# node overall cpu power
	# * *Args* :
	# - +vzcpucheck_text+ -> output of the /usr/sbin/vzcpucheck command execution
	# * *Returns* :
	# - current_cpu_utilization, node_cpu_power parameters of system as strings
	def self.parse_cpu_power(vzcpucheck_text)
		vzcpucheck_text = vzcpucheck_text.split(/\n/)
		current_util = vzcpucheck_text[0].split(/:/)[1].strip
		node_power = vzcpucheck_text[1].split(/:/)[1].strip
		return current_util, node_power
	end

	# TODO write doc
	def self.parse_memcheck(vzmemcheck_text)
		vzmemcheck_text = vzmemcheck_text.drop(3)
		vzmemcheck =  vzmemcheck_text.to_s.split
		alloc_util, alloc_commit, alloc_limit = vzmemcheck[5], vzmemcheck[6], vzmemcheck[7]
	end
end


if __FILE__ == $0
	IMOpenVZDriver.print
end

