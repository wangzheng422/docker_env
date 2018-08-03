# ES人工智能搜索验证

## 参考项目

<https://github.com/o19s/elasticsearch-learning-to-rank>

## 中文分词

ES必须配置中文分词，才能搜索中文，首先要装中文分词插件，我们就用官方的smartcn好了。

```bash
RUN bin/elasticsearch-plugin install analysis-smartcn
```

然后，发现现在的index，没激活中文分词功能，那么需要创建新的index

``` json
PUT /wzh_06
{
    "index.analysis.analyzer.default.type": "smartcn" 
}
```

然后把数据copy进去

```json
POST _reindex
{
  "source": {
    "index": "udbtl_v20180704",
    "type": "X_ML_ACH_CORE_DESC"
  },
  "dest": {
    "index": "wzh_06",
    "type": "X_ML_ACH_CORE_DESC"
  }
}
```

## 特征值

调查发现，中文字段很少，就2个，那么我们就用这两个作为特征值好了。

```json
{
    "query": {
        "multi_match":{
            "query": "{{keywords}}",
            "fields": ["REMARKS"]
        }
    }
}
```

```json
{
    "query": {
        "multi_match":{
            "query": "{{keywords}}",
            "fields": ["LITHOLOGY_OILNESS_DESC"]
        }
    }
}
```

## 训练

运行编译好的训练镜像

```bash
docker run -it es_ai:wzh bash
```

然后到目录demo下面，运行

```bash
python3 loadFeatures.py
python3 collectFeatures.py
python3 train.py
```

完成特征值的创建，采集特征值，训练的步骤。

关键就是 sample_judgments.txt， 我们的sample_judgments.txt是这样的

```
# qid:1: 味淡

0   qid:1 #	1004010_TL_39C946FCB2475BE3E054A0369F40D978
```

意思是，查找“味淡”的时候，把这个doc排除出去。

## 效果

用传统方式查询

```json
POST _search
{
    "query": {
      "multi_match": {
          "query": "味淡",
          "fields": ["REMARKS", "LITHOLOGY_OILNESS_DESC"]
       }
   }
}
```

看到的结果

```json
{
  "took": 58,
  "timed_out": false,
  "_shards": {
    "total": 327,
    "successful": 327,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 12739,
    "max_score": 7.306591,
    "hits": [
      {
        "_index": "wzh_06",
        "_type": "X_ML_ACH_CORE_DESC",
        "_id": "1004010_TL_39C946FCBB125BE3E054A0369F40D978",
        "_score": 7.306591,
        "_source": {
          "UA_ABBR_CODE": "A1",
          "DSID": "1004010_TL_39C946FCBB125BE3E054A0369F40D978",
          "AUDITOR": "*********",
          "WELLBORE_ID": "WEBHTL100003589",
          "DATA_REGION": "TL",
          "CORE_DESC_ID": "39C946FCBB125BE3E054A0369F40D978",
          "LITHOLOGY_OILNESS_DESC": "**********",
          "WELL_COMMON_NAME": "********",
          "CUT_RECOVERED": 1,
          "INTERVAL_BASE": *********,
          "CORE_ID": "39C92E9AE0345A53E054A0369F40D978",
          "DEPTH_INCREMENT": 5,
          "WELL_ID": "WELLTL100018528",
          "CORING_SEQ": "1",
          "WELLBORE_COMMON_NAME": "******",
          "CREATE_DATE": "********",
          "INTERVAL_TOP": *********
        }
      }
      .....
}
```

用增强方式查询

```json
POST _search
{
  "rescore": {
    "query": {
      "rescore_query": {
        "sltr": {
          "model": "test_6",
          "params": {
            "keywords": "味淡"
          }
        }
      }
    }
  },
  "query": {
    "multi_match": {
      "query": "味淡",
      "fields": ["REMARKS", "LITHOLOGY_OILNESS_DESC"]
    }
  }
}
```

得到结果

```json
{
  "took": 199,
  "timed_out": false,
  "_shards": {
    "total": 327,
    "successful": 327,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 12739,
    "max_score": 7.306591,
    "hits": [
      {
        "_index": "wzh_06",
        "_type": "X_ML_ACH_CORE_DESC",
        "_id": "1004010_TL_39C946FCBB125BE3E054A0369F40D978",
        "_score": 7.306591,
        "_source": {
          "UA_ABBR_CODE": "A1",
          "DSID": "1004010_TL_39C946FCBB125BE3E054A0369F40D978",
          "AUDITOR": "*********",
          "WELLBORE_ID": "************",
          "DATA_REGION": "TL",
          "CORE_DESC_ID": "39C946FCBB125BE3E054A0369F40D978",
          "LITHOLOGY_OILNESS_DESC": "***********",
          "WELL_COMMON_NAME": "***********",
          "CUT_RECOVERED": 1,
          "INTERVAL_BASE": ************,
          "CORE_ID": "39C92E9AE0345A53E054A0369F40D978",
          "DEPTH_INCREMENT": 5,
          "WELL_ID": "***********",
          "CORING_SEQ": "1",
          "WELLBORE_COMMON_NAME": "*********",
          "CREATE_DATE": "************",
          "INTERVAL_TOP": ********
        }
      }
      .......
}
```

会发现，有remarks的条目，消失了。

## ES AI search commands

python3 indexMlTmdb.py

python3 loadFeatures.py

python3 judgments.py sample_judgments.txt

python3 collectFeatures.py

python3 train.py

python3 search.py rambo