#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
cat << "EOF" 
   _____       _      _     __      ________      __ 
  / ___/__  __(_)____(_)___/ /___ _/ / ____/___ _/ /_
  \__ \/ / / / / ___/ / __  / __ `/ / /   / __ `/ __/
 ___/ / /_/ / / /__/ / /_/ / /_/ / / /___/ /_/ / /_  
/____/\__,_/_/\___/_/\__,_/\__,_/_/\____/\__,_/\__/  
                                                     
Author: SuicidalCat
Translator: yaxisvip
Github: https://github.com/SuicidalCat/Airport-toolkit                                
EOF
echo "Ubuntu 18.04 x64的代理节点安装脚本"
[ $(id -u) != "0" ] && { echo "Error: 您必须是root才能运行此脚本"; exit 1; }
ARG_NUM=$#
TEMP=`getopt -o hvV --long is_auto:,connection_method:,is_mu:,webapi_url:,webapi_token:,db_ip:,db_name:,db_user:,db_password:,node_id:-- "$@" 2>/dev/null`
[ $? != 0 ] && echo "ERROR: unknown argument!" && exit 1
eval set -- "${TEMP}"
while :; do
  [ -z "$1" ] && break;
  case "$1" in
	--is_auto)
      is_auto=y; shift 1
      [ -d "/soft/shadowsocks" ] && { echo "Shadowsocksr服务器软件已经存在"; exit 1; }
      ;;
    --connection_method)
      connection_method=$2; shift 2
      [[ ! ${connection_method} =~ ^[1-2]$ ]] && { echo "答案不对！ 请输入数字1~2"; exit 1; }
      ;;
    --is_mu)
      is_mu=y; shift 1
      ;;
    --webapi_url)
      webapi_url=$2; shift 2
      ;;
    --webapi_token)
      webapi_token=$2; shift 2
      ;;
    --db_ip)
      db_ip=$2; shift 2
      ;;
    --db_name)
      db_name=$2; shift 2
      ;;
    --db_user)
      db_user=$2; shift 2
      ;;
    --db_password)
      db_password=$2; shift 2
      ;;
    --node_id)
      node_id=$2; shift 2
      ;;
    --)
      shift
      ;;
    *)
      echo "ERROR: unknown argument!" && exit 1
      ;;
  esac
done
if [[ ${is_auto} != "y" ]]; then
	echo "按Y继续安装过程，或按任意键退出。"
	read is_install
	if [[ ${is_install} != "y" && ${is_install} != "Y" ]]; then
    	echo -e "安装已取消......"
    	exit 0
	fi
fi
echo "Checking the universe repository configuration..."
apt install software-properties-common && apt-add-repository universe
echo "Updating exsit package..."
apt clean all && apt autoremove -y && apt update && apt upgrade -y && apt dist-upgrade -y
echo "Installing necessary package..."
apt install git python python-setuptools python-pip build-essential ntpdate htop -y
echo "Please select correct system timezone for your node."
dpkg-reconfigure tzdata
echo "Installing libsodium..."
wget https://github.com/jedisct1/libsodium/releases/download/1.0.17/libsodium-1.0.17.tar.gz
tar xf libsodium-1.0.17.tar.gz && cd libsodium-1.0.17
./configure && make -j2 && make install
echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig
cd ../ && rm -rf libsodium*
if [ ! -d "/soft" ]; then
	mkdir /soft
else
	echo "/soft directory is already exist..."
fi
cd /soft
echo "检查是否存在Shadowsocksr服务器软件..."
if [ ! -d "shadowsocks" ]; then
	echo "从GitHub安装Shadowsocksr服务器..."
	cd /tmp && git clone -b manyuser https://github.com/yaxisvip/shadowsocks.git
	mv -f shadowsocks /soft
else
	while :; do echo
		echo -n "Shadowsocksr服务器软件已经存在！ 你想升级吗？(Y/N)"
		read is_mu
		if [[ ${is_mu} != "y" && ${is_mu} != "Y" && ${is_mu} != "N" && ${is_mu} != "n" ]]; then
			echo -n "Bad answer! Please only input number Y or N"
		elif [[ ${is_mu} == "y" && ${is_mu} == "Y" ]]; then
			echo "升级Shadowsocksr服务器软件......"
			cd shadowsocks && git pull
			break
		else
			exit 0
		fi
	done
fi
cd /soft/shadowsocks
python -m pip install --upgrade pip setuptools
python -m pip install -r requirements.txt
echo "生成配置文件..."
cp apiconfig.py userapiconfig.py
cp config.json user-config.json
if [[ ${is_auto} != "y" ]]; then
	#Choose the connection method
	while :; do echo
		echo -e "请选择节点服务器连接方式的方式："
		echo -e "\t1. WebAPI"
		echo -e "\t2. 远程数据库"
		read -p "请输入一个数字:(默认2按Enter键）" connection_method
		[ -z ${connection_method} ] && connection_method=2
		if [[ ! ${connection_method} =~ ^[1-2]$ ]]; then
			echo "答案不对！ 请输入数字1~2"
		else
			break
		fi			
	done
	while :; do echo
		echo -n "是否要在单端口功能中启用多用户？(Y/N)"
		read is_mu
		if [[ ${is_mu} != "y" && ${is_mu} != "Y" && ${is_mu} != "N" && ${is_mu} != "n" ]]; then
			echo -n "答案不对！ 请仅输入数字Y或N."
		else
			break
		fi
	done
fi
do_mu(){
	if [[ ${is_auto} != "y" ]]; then
		echo -n "请输入MU_SUFFIX:"
		read mu_suffix
		echo -n "请输入MU_REGEX:"
		read mu_regex
		echo "写入MU配置..."
	fi
	sed -i -e "s/MU_SUFFIX = 'zhaoj.in'/MU_SUFFIX = '${mu_suffix}'/g" -e "s/MU_REGEX = 'zhaoj.in'/MU_REGEX = '${mu_regex}'/g" userapiconfig.py
}
do_modwebapi(){
	if [[ ${is_auto} != "y" ]]; then
		echo -n "请输入WebAPI url:"
		read webapi_url
		echo -n "请输入WebAPI token:"
		read webapi_token
		echo -n "请输入服务器节点ID:"
		read node_id
	fi
	if [[ ${is_mu} == "y" || ${is_mu} == "Y" ]]; then
		do_mu
	fi
	echo "写入连接配置..."
	sed -i -e "s/NODE_ID = 0/NODE_ID = ${node_id}/g" -e "s%WEBAPI_URL = 'https://zhaoj.in'%WEBAPI_URL = '${webapi_url}'%g" -e "s/WEBAPI_TOKEN = 'glzjin'/WEBAPI_TOKEN = '${webapi_token}'/g" userapiconfig.py
}
do_glzjinmod(){
	if [[ ${is_auto} != "y" ]]; then
		sed -i -e "s/'modwebapi'/'glzjinmod'/g" userapiconfig.py
		echo -n "请输入数据库服务器的IP地址："
		read db_ip
		echo -n "数据库名称："
		read db_name
		echo -n "数据库用户名："
		read db_user
		echo -n "数据库密码："
		read db_password
		echo -n "服务器节点ID："
		read node_id
	fi
	if [[ ${is_mu} == "y" || ${is_mu} == "Y" ]]; then
		do_mu
	fi
	echo "写入连接配置..."
	sed -i -e "s/NODE_ID = 1/NODE_ID = ${node_id}/g" -e "s/MYSQL_HOST = '127.0.0.1'/MYSQL_HOST = '${db_ip}'/g" -e "s/MYSQL_USER = 'ss'/MYSQL_USER = '${db_user}'/g" -e "s/MYSQL_PASS = 'ss'/MYSQL_PASS = '${db_password}'/g" -e "s/MYSQL_DB = 'shadowsocks'/MYSQL_DB = '${db_name}'/g" userapiconfig.py
}
if [[ ${is_auto} != "y" ]]; then
	#Do the configuration
	if [ "${connection_method}" == '1' ]; then
		do_modwebapi
	elif [ "${connection_method}" == '2' ]; then
		do_glzjinmod
	fi
fi
do_bbr(){
	echo "运行系统优化并启用BBR ..."
	echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
	cat >> /etc/security/limits.conf << EOF
	* soft nofile 51200
	* hard nofile 51200
EOF
	ulimit -n 51200
	cat >> /etc/sysctl.conf << EOF
	fs.file-max = 51200
	net.core.default_qdisc = fq
	net.core.rmem_max = 67108864
	net.core.wmem_max = 67108864
	net.core.netdev_max_backlog = 250000
	net.core.somaxconn = 4096
	net.ipv4.tcp_congestion_control = bbr
	net.ipv4.tcp_syncookies = 1
	net.ipv4.tcp_tw_reuse = 1
	net.ipv4.tcp_fin_timeout = 30
	net.ipv4.tcp_keepalive_time = 1200
	net.ipv4.ip_local_port_range = 10000 65000
	net.ipv4.tcp_max_syn_backlog = 8192
	net.ipv4.tcp_max_tw_buckets = 5000
	net.ipv4.tcp_fastopen = 3
	net.ipv4.tcp_rmem = 4096 87380 67108864
	net.ipv4.tcp_wmem = 4096 65536 67108864
	net.ipv4.tcp_mtu_probing = 1
EOF
	sysctl -p
}
do_service(){
	echo "写入系统配置..."
	wget https://raw.githubusercontent.com/SuicidalCat/Airport-toolkit/master/ssr_node.service
	chmod 754 ssr_node.service && mv ssr_node.service /etc/systemd/system
	echo "启动SSR节点服务......"
	systemctl enable ssr_node && systemctl start ssr_node
}
while :; do echo
	echo -n "你想启用BBR功能(from mainline kernel) 并优化系统吗？(Y/N)"
	read is_bbr
	if [[ ${is_bbr} != "y" && ${is_bbr} != "Y" && ${is_bbr} != "N" && ${is_bbr} != "n" ]]; then
		echo -n "答案不好！请输入数字Y或N"
	else
		break
	fi
done
while :; do echo
	echo -n "你想将SSR节点注册为系统服务吗？(Y/N)"
	read is_service
	if [[ ${is_service} != "y" && ${is_service} != "Y" && ${is_service} != "N" && ${is_service} != "n" ]]; then
		echo -n "答案不好！请输入数字Y或N"
	else
		break
	fi
done
if [[ ${is_bbr} == "y" || ${is_bbr} == "Y" ]]; then
	do_bbr
fi
if [[ ${is_service} == "y" || ${is_service} == "Y" ]]; then
	do_service
fi
echo "安装完成后，请运行 python /soft/shadowsocks/server.py 进行测试。"
