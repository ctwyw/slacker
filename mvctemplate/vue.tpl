  <!-- Generated by slacker--> 
<template>
  <el-card>
    <div slot="header">
      <el-form :inline="true" v-model="searchform" @submit.native.prevent="none">
        <el-form-item>
          <el-input prefix-icon="el-icon-search" clearable v-model.trim="searchform.ip" placeholder="查找内容"></el-input>
        </el-form-item> 
        <el-form-item>
          <el-button type="primary" @click="Search" icon="el-icon-search">查询</el-button>
          <el-button @click="resetsearchform">清空查询条件</el-button>
        </el-form-item>
      </el-form>
      <el-button @click="importfile.visible=true" round type="primary" class="card-button"><i class="el-icon-upload2"></i>导入表格</el-button>
      <el-button @click="Export" type="primary" round class="card-button"><i class="el-icon-download"></i>导出表格</el-button>
      <el-button @click="create.visible = true" type="primary" round class="card-button" icon="el-icon-plus">添加</el-button>
      <div style="clear:both"></div>
    </div>
    <el-table :data="table.data" style="width: 100%" @selection-change="SelectionChange" v-loading="table.loading">
      <el-table-column type="selection" width="55">
      </el-table-column>
        {{range $i,$col:=.Columns}}
      <el-table-column label="{{$col.CamelCaseName}}">
        <template slot-scope="scope">
          <span> <<< scope.row.{{$col.ColumnName}} >>> </span>
        </template>
      </el-table-column>
         {{end}}
      <el-table-column label="操作">
        <template slot-scope="scope">
          <el-button size="small" type="primary" plain @click="update.form = Object.assign({},scope.row);update.visible = true" icon="el-icon-edit"> </el-button>
          <el-button size="small" type="danger" @click="Delete(scope.row)" icon="el-icon-delete"></el-button>
        </template>
      </el-table-column>
    </el-table>
    <div style="margin-left: 20px;margin-top: 20px">
      <el-button v-show="multipleSelection.length" type="primary" @click="ClickBatchPatch">批量修改</el-button>
      <el-button v-show="multipleSelection.length" type="danger" @click="ClickBatchDelete">批量删除</el-button>
    </div>
    <el-pagination class="pagination" background layout=" sizes, total, prev, pager, next" :total="table.total" :page-size="table.limit" :page-sizes="[10, 50, 100, 999]" @size-change="SizeChange" @current-change="PageChange">
    </el-pagination>

    <el-dialog title="添加" :visible.sync="create.visible" width="500px">
      <el-form :model="create.form" label-position="right" label-width="100px">
           {{range $i,$col:=.Columns}}
        <el-form-item label="{{$col.CamelCaseName}}">
        
          <el-input v-model.{{if Contains $col.Type "int"}}number{{else}}trim{{end}}="create.form.{{$col.ColumnName}}" auto-complete="off"></el-input>
        </el-form-item>
          {{end}}
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="create.visible = false">取 消</el-button>
        <el-button type="primary" @click="Create">确 定</el-button>
      </div>
    </el-dialog>

    <el-dialog title="编辑" :visible.sync="update.visible" width="500px">
      <el-form :model="update.form" label-position="right" label-width="100px">
      {{range $i,$col:=.Columns}}
        <el-form-item label="{{$col.CamelCaseName}}">
          <el-input v-model.{{if Contains $col.Type "int"}}number{{else}}trim{{end}}="update.form.{{$col.ColumnName}}" auto-complete="off"></el-input>
        </el-form-item>
          {{end}}
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="update.visible = false">取 消</el-button>
        <el-button type="primary" @click="Update">确 定</el-button>
      </div>
    </el-dialog>

    <el-dialog title="批量修改" :visible.sync="batchpatch.visible" width="500px">
      <el-form :model="batchpatch.form" label-position="right" label-width="100px">
            {{range $i,$col:=.Columns}}
        <el-form-item label="{{$col.CamelCaseName}}">
          <el-input v-model.{{if Contains $col.Type "int"}}number{{else}}trim{{end}}="batchpatch.form.{{$col.ColumnName}}" auto-complete="off"></el-input>
        </el-form-item>
          {{end}}
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="batchpatch.visible = false">取 消</el-button>
        <el-button type="primary" @click="BatchPatch">确 定</el-button>
      </div>
    </el-dialog>

     <el-dialog title="提示:上传后将改变原有数据" :visible.sync="importfile.visible" width="30%">
      <el-upload ref="upload" :on-change="FileChange" :file-list="importfile.filelist" :http-request="Import" :auto-upload="false" drag action="">
        <i class="el-icon-upload"></i>
        <div class="el-upload__text">将文件拖到此处，或
          <em>点击上传</em>
        </div>
        <div class="el-upload__tip" slot="tip">只能上传.xlsx文件</div>
      </el-upload>
      <span slot="footer" class="dialog-footer">
        <el-button @click="importfile.visible = false">取 消</el-button>
        <el-button type="primary" @click="submitUpload">确 定</el-button>
      </span>
    </el-dialog>
  </el-card>
</template>

<script>
  import * as api from "@/api/{{.Name}}";
  export default {
    data() {
      return {
        multipleSelection: [],
        table: {
          loading: false,
          data: [],
          total: 0,
          offset: 0,
          limit: 10
        },
        searchform: {},
        create: {
          form: {},
          visible: false
        },
        update: {
          form: {},
          visible: false
        },
        batchpatch: {
          form: {},
          visible: false
        },
        importfile: {
          filelist: [],
          visible: false
        }
      };
    },
    methods: {
      getdata() {
        this.table.loading = true;
        api
          .List(
            Object.assign(
              { offset: this.table.offset, limit: this.table.limit },
              this.searchform
            )
          )
          .then(rsp => {
            this.table.total = rsp.data.total;
            this.table.data = rsp.data.data;
            this.table.loading = false;
          })
          .catch(err => {});
      },
      PageChange(val) {
        this.table.offset = this.table.limit * (val - 1);
        this.getdata();
      },
      SizeChange(val) {
        this.table.limit = val;
        this.getdata();
      },
      resetcreateform() {
        this.create.visible = false;
        this.create.form = {};
      },
      resetsearchform() {
        this.searchform = {};
        this.Search();
      },
      Search() {
        this.table.offset = 0;
        this.getdata();
      },
      Create() {
        let loading = this.$loading({
          lock: true,
          text: "操作中...",
          spinner: "el-icon-loading",
          background: "rgba(0, 0, 0, 0.7)"
        });
        api
          .Create(this.create.form)
          .then(rsp => {
            this.resetcreateform();
            this.getdata();
          })
          .catch(err => {})
          .then(() => {
            loading.close();
          });
      },
      Delete(row) {
        this.$confirm("此操作将删除此条数据, 是否继续?", "提示", {
          confirmButtonText: "确定",
          cancelButtonText: "取消",
          type: "warning"
        })
          .then(() => {
            api
              .Delete(row.{{.PrimaryKeyColumn.ColumnName}})
              .then(rsp => {
                this.$notify.success("删除成功");
                this.getdata();
              })
              .catch(err => {});
          })
          .catch(err => {});
      },
      Update() {
        api
          .Update(this.update.form.{{.PrimaryKeyColumn.ColumnName}}, this.update.form)
          .then(rsp => {
            this.update.visible = false;
            this.$notify.success("更新成功");
            this.getdata();
          })
          .catch(err => {});
      },
      SelectionChange(val) {
        this.multipleSelection = val;
      },
      ClickBatchDelete() {
        this.$confirm("批量删除选中的条目, 是否继续?", "提示", {
          confirmButtonText: "确定",
          cancelButtonText: "取消",
          type: "warning"
        })
          .then(() => {
            this.BatchDelete();
          })
          .catch(() => {});
      },
      BatchDelete() {
        let loading = this.$loading({
          lock: true,
          text: "操作中...",
          spinner: "el-icon-loading",
          background: "rgba(0, 0, 0, 0.7)"
        });
        let ids = [];
        for (let index = 0; index < this.multipleSelection.length; index++) {
          const item = this.multipleSelection[index];
          ids.push(item.{{.PrimaryKeyColumn.ColumnName}});
        }
        api
          .BatchDelete({ {{.PrimaryKeyColumn.ColumnName}}:ids })
          .then(rsp => {
            this.$notify.success("删除成功");
            this.getdata();
          })
          .catch(err => {})
          .then(() => {
            loading.close();
          });
      },
      ClickBatchPatch() {
        this.batchpatch.form = {};
        this.batchpatch.visible = true;
      },
      BatchPatch() {
        let loading = this.$loading({
          lock: true,
          text: "操作中...",
          spinner: "el-icon-loading",
          background: "rgba(0, 0, 0, 0.7)"
        });
        let ids = [];
        for (let index = 0; index < this.multipleSelection.length; index++) {
          const item = this.multipleSelection[index];
          ids.push(item.{{.PrimaryKeyColumn.ColumnName}});
        }
        api
          .BatchPatch( { {{.PrimaryKeyColumn.ColumnName}}:ids }, this.batchpatch.form)
          .then(rsp => {
            this.$notify.success("修改成功");
            this.getdata();
            this.batchpatch.visible = false;
          })
          .catch(err => {})
          .then(() => {
            loading.close();
          });
      },
      Export() {
        api.Export();
      },
      Import(item) {
        var type =
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
        if (
          item.file.type !== type &&
          item.file.type !== "application/wps-office.xlsx"
        ) {
          this.$message.error("只能上传xlsx格式");
          return;
        }
        this.$loading({
          lock: true
        });

        api
          .Import(item.file)
          .then(rsp => {
            this.$notify.success("导入成功");
            this.importfile.visible = false;
          })
          .catch(err => {})
          .then(() => {
            this.$loading().close();
            this.getdata();
          });
      },
      submitUpload() {
        this.$refs.upload.submit();
      },
      FileChange(file, list) {
        this.importfile.filelist = [list.pop()];
      },
      none(){}
    }, 
    created() {
      this.getdata(); 
    }
  };
</script>

 