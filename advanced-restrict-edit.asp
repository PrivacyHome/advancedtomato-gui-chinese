<!--
Tomato GUI
Copyright (C) 2006-2010 Jonathan Zarate
http://www.polarcloud.com/tomato/

For use with Tomato Firmware only.
No part of this file may be used without permission.
--><title>编辑访问限制</title>
<content>
	<script type="text/javascript" src="js/protocols.js"></script>
	<style type="text/css">
		#res-comp-grid {
			width: 60%;
		}

		input, select {
			display: inline-block;
			width: auto !important;
			margin-right: 2px;
		}

		textarea {
			height: 20em;
			width: 100%;
		}
	</style>
	<script type="text/javascript">
		//	<% nvram(''); %>	// http_id

		// {enable}|{begin_mins}|{end_mins}|{dow}|{comp[<comp]}|{rules<rules[...]>}|{http[ ...]}|{http_file}|{desc}
		//	<% rrule(); %>
		if ((rule = rrule.match(/^(\d+)\|(-?\d+)\|(-?\d+)\|(\d+)\|(.*?)\|(.*?)\|([^|]*?)\|(\d+)\|(.*)$/m)) == null) {
			rule = ['', 1, 1380, 240, 31, '', '', '', 0, '新规则 ' + (rruleN + 1)];
		}
		rule[2] *= 1;
		rule[3] *= 1;
		rule[4] *= 1;
		rule[8] *= 1;

		// <% layer7(); %>
		layer7.sort();
		for (i = 0; i < layer7.length; ++i)
			layer7[i] = [layer7[i],layer7[i]];
		layer7.unshift(['', '7层 (禁用)']);

		var ipp2p = [
			[0,'IPP2P (禁用)'],[0xFFFF,'All IPP2P Filters'],[1,'AppleJuice'],[2,'Ares'],[4,'BitTorrent'],[8,'Direct Connect'],
			[16,'eDonkey'],[32,'Gnutella'],[64,'Kazaa'],[128,'Mute'],[4096,'PPLive/UUSee'],[256,'SoulSeek'],[512,'Waste'],[1024,'WinMX']
			/* LINUX26-BEGIN */
			,[2048,'XDCC'],[8192,'Xunlei/QQCyclone']
			/* LINUX26-END */
		];

		var dowNames = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];

		//

		var cg = new TomatoGrid();

		cg.verifyFields = function(row, quiet) {
			var f = fields.getAll(row)[0];
			if (v_mac(f, true)) return true;
			if (_v_iptaddr(f, true, false, true, true)) return true;

			ferror.set(f, '无效的 MAC 或 IP 地址/范围', quiet);
			return false;
		}

		cg.setup = function() {
			var a, i, count, ex;

			this.init('res-comp-grid', 'sort', 500, [ { type: 'text', maxlen: 32 } ] );
			this.headerSet(['MAC / IP 地址']);
			this.showNewEditor();
			this.resetNewEditor();

			if (rule[5] == '~') return;	// wireless disable rule

			ex = 0;
			count = 0;
			a = rule[5].split('>');
			for (i = 0; i < a.length; ++i) {
				if (!a[i].length) continue;
				if (a[i] == '!') {
					ex = 1;
				}
				else {
					cg.insertData(-1, [a[i]]);
					++count;
				}
			}

			a = E('_f_comp_all')
			if (count) {
				a.value = ex ? 2 : 1;
			}
			else {
				a.value = 0;
			}
		}


		var bpg = new TomatoGrid();

		bpg.verifyFields = function(row, quiet) {
			var f = fields.getAll(row);
			ferror.clearAll(f);
			this.enDiFields(row);

			if ((f[5].selectedIndex != 0) && ((!v_length(f[6], quiet, 1)) || (!_v_iptaddr(f[6], quiet, false, true, true)))) return 0;
			if ((f[1].selectedIndex != 0) && (!v_iptport(f[2], quiet))) return 0;

			if ((f[1].selectedIndex == 0) && (f[3].selectedIndex == 0) && (f[4].selectedIndex == 0) && (f[5].selectedIndex == 0)) {
				var m = '请输入一个特定的地址或端口，或选择一个应用程序匹配';
				ferror.set(f[3], m, 1);
				ferror.set(f[4], m, 1);
				ferror.set(f[5], m, 1);
				ferror.set(f[1], m, quiet);
				return 0;
			}

			ferror.clear(f[1]);
			ferror.clear(f[3]);
			ferror.clear(f[4]);
			ferror.clear(f[5]);
			ferror.clear(f[6]);
			return 1;
		}

		bpg.dataToView = function(data) {
			var s, i;

			s = '';
			if (data[5] != 0) s = ((data[5] == 1) ? '到 ' : '从 ') + data[6] + ', ';

			if (data[0] <= -2) s += (s.length ? 'a' : 'A') + 'ny protocol';
			else if (data[0] == -1) s += 'TCP/UDP';
				else if (data[0] >= 0) s += protocols[data[0]] || data[0];

			if (data[0] >= -1) {
				if (data[1] == 'd') s += ', 目标端口 ';
				else if (data[1] == 's') s += ', 源端口 ';
					else if (data[1] == 'x') s += ', 端口 ';
						else s += ', 所有端口';
				if (data[1] != 'a') s += data[2].replace(/:/g, '-');
			}

			if (data[3] != 0) {
				for (i = 0; i < ipp2p.length; ++i) {
					if (data[3] == ipp2p[i][0]) {
						s += ', IPP2P: ' + ipp2p[i][1];
						break;
					}
				}
			}
			else if (data[4] != '') {
				s += ', L7: ' + data[4];
			}

			return [s];
		}

		bpg.fieldValuesToData = function(row) {
			var f = fields.getAll(row);
			return [f[0].value, f[1].value, (f[1].selectedIndex == 0) ? '' : f[2].value, f[3].value, f[4].value, f[5].value, (f[5].selectedIndex == 0) ? '' : f[6].value];
		},

		bpg.resetNewEditor = function() {
			var f = fields.getAll(this.newEditor);
			f[0].selectedIndex = 0;
			f[1].selectedIndex = 0;
			f[2].value = '';
			f[3].selectedIndex = 0;
			f[4].selectedIndex = 0;
			f[5].selectedIndex = 0;
			f[6].value = '';
			this.enDiFields(this.newEditor);
			ferror.clearAll(fields.getAll(this.newEditor));
		}

		bpg._createEditor = bpg.createEditor;
		bpg.createEditor = function(which, rowIndex, source) {
			var row = this._createEditor(which, rowIndex, source);
			if (which == 'edit') this.enDiFields(row);
			return row;
		}

		bpg.enDiFields = function(row) {
			var x;
			var f = fields.getAll(row);

			x = f[0].value;
			x = ((x != -1) && (x != 6) && (x != 17));
			f[1].disabled = x;
			if (f[1].selectedIndex == 0) x = 1;
			f[2].disabled = x;
			f[3].disabled = (f[4].selectedIndex != 0);
			f[4].disabled = (f[3].selectedIndex != 0);
			f[6].disabled = (f[5].selectedIndex == 0);
		}

		bpg.setup = function() {
			var a, i, r, count, protos;

			protos = [[-2, '所有协议'],[-1,'TCP/UDP'],[6,'TCP'],[17,'UDP']];
			for (i = 0; i < 256; ++i) {
				if ((i != 6) && (i != 17)) protos.push([i, protocols[i] || i]);
			}

			this.init('res-bp-grid', 'sort', 500, [ { multi: [
				{ type: 'select', options: protos },
				{ type: 'select',
					options: [['a','所有端口'],['d','目标端口'],['s','源端口'],['x','源 或 目标']] },
				{ type: 'text', maxlen: 32 },
				{ type: 'select', options: ipp2p },
				{ type: 'select', options: layer7 },
				{ type: 'select',
					options: [[0,'所有地址'],[1,'目标 IP'],[2,'源 IP']] },
				{ type: 'text', maxlen: 64 }
			] } ] );
			this.headerSet(['策略']);
			this.showNewEditor();
			this.resetNewEditor();
			count = 0;

			// ---- proto<dir<port<ipp2p<layer7[<addr_type<addr]

			a = rule[6].split('>');
			for (i = 0; i < a.length; ++i) {
				r = a[i].split('<');
				if (r.length == 5) {
					// ---- fixup for backward compatibility
					r.push('0');
					r.push('');
				}
				if (r.length == 7) {
					r[2] = r[2].replace(/:/g, '-');
					this.insertData(-1, r);
					++count;
				}
			}
			return count;
		}

		//

		function verifyFields(focused, quiet)
		{
			var b, e;

			tgHideIcons();

			elem.display(PR('_f_sched_begin'), !E('_f_sched_allday').checked);
			elem.display(PR('_f_sched_sun'), !E('_f_sched_everyday').checked);

			b = E('rt_norm').checked;
			elem.display(PR('_f_comp_all'), PR('_f_block_all'), b);

			elem.display(PR('res-comp-grid'), b && E('_f_comp_all').value != 0);
			elem.display(PR('res-bp-grid'), PR('_f_block_http'), PR('_f_activex'), b && !E('_f_block_all').checked);

			ferror.clear('_f_comp_all');

			e = E('_f_block_http');
			e.value = e.value.replace(/[|"']/g, ' ');
			if (!v_length(e, quiet, 0, 2048 - 16)) return 0;

			e = E('_f_desc');
			e.value = e.value.replace(/\|/g, '_');
			if (!v_length(e, quiet, 1)) return 0;

			return 1;
		}

		function cancel()
		{
			document.location = '/#advanced-restrict.asp';
		}

		function delRULE()
		{

			if (!confirm('确认删除此策略吗?')) return;

			E('delete-button').disabled = 1;

			e = E('_rrule');
			e.name = 'rrule' + rruleN;
			e.value = '';
			form.submit('_fom');
		}

		function save()
		{
			if (!verifyFields(null, false)) return;
			if ((cg.isEditing()) || (bpg.isEditing())) return;

			var a, b, e, s, n, data;

			data = [];
			data.push(E('_f_enabled').checked ? '1' : '0');
			if (E('_f_sched_allday').checked) data.push(-1, -1);
			else data.push(E('_f_sched_begin').value, E('_f_sched_end').value);

			if (E('_f_sched_everyday').checked) {
				n = 0x7F;
			}
			else {
				n = 0;
				for (i = 0; i < 7; ++i) {
					if (E('_f_sched_' + dowNames[i].toLowerCase()).checked) n |= (1 << i);
				}
				if (n == 0) n = 0x7F;
			}
			data.push(n);

			if (E('rt_norm').checked) {
				e = E('_f_comp_all');
				if (e.value != 0) {
					a = cg.getAllData();
					if (a.length == 0) {
						ferror.set(e, 'MAC 错误或 IP 地址已被指定', 0);
						return;
					}
					if (e.value == 2) a.unshift('!');
					data.push(a.join('>'));
				}
				else {
					data.push('');
				}

				if (E('_f_block_all').checked) {
					data.push('', '', '0');
				}
				else {
					var check = 0;
					a = bpg.getAllData();
					check += a.length;
					b = [];
					for (i = 0; i < a.length; ++i) {
						a[i][2] = a[i][2].replace(/-/g, ':');
						b.push(a[i].join('<'));
					}
					data.push(b.join('>'));

					a = E('_f_block_http').value.replace(/\r+/g, ' ').replace(/\n+/g, '\n').replace(/ +/g, ' ').replace(/^\s+|\s+$/g, '');
					check += a.length;
					data.push(a);

					n = 0;
					if (E('_f_activex').checked) n = 1;
					if (E('_f_flash').checked) n |= 2;
					if (E('_f_java').checked) n |= 4;
					data.push(n);

					if (((check + n) == 0) && (data[0] == 1)) {
						alert('请具体指明哪些项目应该被阻止.');
						return;
					}
				}
			}
			else {
				data.push('~');
				data.push('', '', '', '0');
			}

			data.push(E('_f_desc').value);
			data = data.join('|');

			if (data.length >= 8192) {
				alert('此规则过大，请减小 ' + (data.length - 8192) + ' 个字符.');
				return;
			}

			e = E('_rrule');
			e.name = 'rrule' + rruleN;
			e.value = data;

			E('delete-button').disabled = 1;
			form.submit('_fom');
		}

		function init() {

			earlyInit();

			cg.recolor();
			bpg.recolor();
		}

		function earlyInit() {
			var count;

			cg.setup();

			count = bpg.setup();
			E('_f_block_all').checked = (count == 0) && (rule[7].search(/[^\s\r\n]/) == -1) && (rule[8] == 0);
			verifyFields(null, 1);
		}
	</script>

	<form name="_fom" id="_fom" method="post" action="tomato.cgi">
		<input type="hidden" name="_nextpage" value="/#advanced-restrict.asp">
		<input type="hidden" name="_service" value="restrict-restart">
		<input type="hidden" name="rruleNN" id="_rrule" value="">

		<div class="box">
			<div class="heading">访问限制 &nbsp; (<span class="restrict-id"></span>)</div>
			<div class="content">
				<div id="restriction"></div><br />
				<script type="text/javascript">
					$('.restrict-id').html('ID: #' + rruleN.pad(2));
					tm = [];
					for (i = 0; i < 1440; i += 15) tm.push([i, timeString(i)]);

					$('#restriction').forms([
						{ title: '启用', name: 'f_enabled', type: 'checkbox', value: rule[1] == '1' },
						{ title: '描述', name: 'f_desc', type: 'text', maxlen: 32, size: 35, value: rule[9] },
						{ title: '时间表', multi: [
							{ name: 'f_sched_allday', type: 'checkbox', suffix: ' 全天 &nbsp; ', value: (rule[2] < 0) || (rule[3] < 0) },
							{ name: 'f_sched_everyday', type: 'checkbox', suffix: ' 每天', value: (rule[4] & 0x7F) == 0x7F } ] },
						{ title: '时间', indent: 2, multi: [
							{ name: 'f_sched_begin', type: 'select', options: tm, value: (rule[2] < 0) ? 0 : rule[2], suffix: ' - ' },
							{ name: 'f_sched_end', type: 'select', options: tm, value: (rule[3] < 0) ? 0 : rule[3] } ] },
						{ title: '天', indent: 2, multi: [
							{ name: 'f_sched_sun', type: 'checkbox', suffix: ' 星期日 &nbsp; ', value: (rule[4] & 1) },
							{ name: 'f_sched_mon', type: 'checkbox', suffix: ' 星期一 &nbsp; ', value: (rule[4] & (1 << 1)) },
							{ name: 'f_sched_tue', type: 'checkbox', suffix: ' 星期二 &nbsp; ', value: (rule[4] & (1 << 2)) },
							{ name: 'f_sched_wed', type: 'checkbox', suffix: ' 星期三 &nbsp; ', value: (rule[4] & (1 << 3)) },
							{ name: 'f_sched_thu', type: 'checkbox', suffix: ' 星期四 &nbsp; ', value: (rule[4] & (1 << 4)) },
							{ name: 'f_sched_fri', type: 'checkbox', suffix: ' 星期五 &nbsp; ', value: (rule[4] & (1 << 5)) },
							{ name: 'f_sched_sat', type: 'checkbox', suffix: ' 星期六', value: (rule[4] & (1 << 6)) } ] },
						{ title: '类型', name: 'f_type', id: 'rt_norm', type: 'radio', suffix: ' 正常的访问限制', value: (rule[5] != '~') },
						{ title: '', name: 'f_type', id: 'rt_wl', type: 'radio', suffix: ' 禁用无线', value: (rule[5] == '~') },
						{ title: '适用于', name: 'f_comp_all', type: 'select', options: [[0,'所有 计算机/设备'],[1,'以下...'],[2,'除了...']], value: 0 },
						{ title: '&nbsp;', text: '<table class="line-table col-sm-9" id="res-comp-grid"></table>' },
						{ title: '封锁网络', name: 'f_block_all', type: 'checkbox', suffix: ' 阻止所有互联网接入', value: 0 },
						{ title: '端口/应用', indent: 2, text: '<table class="line-table col-sm-9" id="res-bp-grid"></table>' },
						{ title: 'HTTP 请求', indent: 2, name: 'f_block_http', type: 'textarea', value: rule[7] },
						{ title: '限制 HTTP 请求的文件', indent: 2, multi: [
							{ name: 'f_activex', type: 'checkbox', suffix: ' ActiveX (ocx, cab) &nbsp;&nbsp;', value: (rule[8] & 1) },
							{ name: 'f_flash', type: 'checkbox', suffix: ' Flash (swf) &nbsp;&nbsp;', value: (rule[8] & 2) },
							{ name: 'f_java', type: 'checkbox', suffix: ' Java (class, jar) &nbsp;&nbsp;', value: (rule[8] & 4) } ] }
					]);
				</script>

				<button type="button" value="删除..." id="delete-button" onclick="delRULE();" class="btn btn-danger"><i class="icon-cancel"></i> 删除</button> &nbsp;
				<button type="button" value="保存设置" id="save-button" onclick="save();" class="btn btn-primary">保存设置
				<button type="button" value="取消设置" id="cancel-button" onclick="cancel();" class="btn">取消设置 <i class="icon-disable"></i></button>
				<span id="footer-msg"></span>
			</div>
		</div>
	</form>

	<script type="text/javascript">init();</script>
</content>