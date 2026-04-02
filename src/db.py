"""
数据库连接模块
通过 SSH 隧道连接 Impala
"""
import warnings
warnings.filterwarnings("ignore")

from sshtunnel import SSHTunnelForwarder
from impala.dbapi import connect
import pandas as pd
from contextlib import contextmanager


class DBConfig:
    def __init__(
        self,
        ssh_host: str,
        ssh_user: str,
        ssh_password: str,
        db_host: str,
        db_port: int,
        db_user: str,
        db_pass: str,
    ):
        self.ssh_host = ssh_host
        self.ssh_user = ssh_user
        self.ssh_password = ssh_password
        self.db_host = db_host
        self.db_port = db_port
        self.db_user = db_user
        self.db_pass = db_pass


@contextmanager
def get_cursor(config: DBConfig):
    """上下文管理器，自动管理 SSH 隧道和数据库连接"""
    with SSHTunnelForwarder(
        (config.ssh_host, 22),
        ssh_username=config.ssh_user,
        ssh_password=config.ssh_password,
        remote_bind_address=(config.db_host, config.db_port),
    ) as tunnel:
        conn = connect(
            host="127.0.0.1",
            port=tunnel.local_bind_port,
            user=config.db_user,
            password=config.db_pass,
            auth_mechanism="PLAIN",
        )
        cursor = conn.cursor()
        try:
            yield cursor
        finally:
            cursor.close()
            conn.close()


def run_query(cursor, sql: str, desc: str = "") -> pd.DataFrame:
    """执行 SQL 并返回 DataFrame"""
    if desc:
        print(f"\n{'='*60}\n【{desc}】\n{'='*60}")
    cursor.execute(sql)
    cols = [d[0] for d in cursor.description]
    rows = cursor.fetchall()
    df = pd.DataFrame(rows, columns=cols)
    if desc:
        print(df.to_string(index=False))
    return df


def test_connection(config: DBConfig) -> bool:
    """测试连接是否正常"""
    try:
        with get_cursor(config) as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        print("✅ 数据库连接成功")
        return True
    except Exception as e:
        print(f"❌ 连接失败: {e}")
        return False
